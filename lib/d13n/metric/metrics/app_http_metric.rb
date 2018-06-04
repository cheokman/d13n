require 'd13n/ext/string'
module D13n::Metric
  class HTTPMetricError < MetricError; end
  class ServiceNotFound < HTTPMetricError; end
  class EndpointNotFound < HTTPMetricError; end
  class AppHttpMetric < Base
    
    module Namespace
      def get_service_endpoint(request)
        service = Helper.service_for(request.uri)
        endpoint = Helper.endpoint_for(request.uri)
        raise ServiceNotFound.new "No matched service for #{request.uri.to_s}" if service.nil?
        raise EndpointNotFound.new "No matched endpoint for #{request.uri.to_s}" if endpoint.nil?
        [service, endpoint]
      end

      def service_metric(request,type)
        service, endpoint = get_service_endpoint(request)
        items = []
        items << prefix
        items << 'service'
        items << service
        items << type.to_s
        items.join('.')
      end

      def endpoint_metric(request, type)
        service, endpoint = get_service_endpoint(request)
        items = []
        items << prefix
        items << 'endpoint'
        items << service
        items << endpoint
        items << type.to_s
        items.join('.')
      end

      def http_basic_tags(request)
        service, endpoint = get_service_endpoint(request)
        tags = []
        tags << "idc:#{D13n.idc_name}"
        tags << "env:#{D13n.idc_env}"
        tags << "app:#{D13n.app_name}"
        tags << "srv:#{service}"
        tags << "endpoint:#{endpoint}"
        tags
      end

      def http_status_tags(request, response)
        tags = http_basic_tags(request)
        tags << "status:#{response.code}"
        tags
      end

      def http_error_tags(response)
        tags = http_basic_tags
        tags << "error:#{response.class.name.underscore}"
        tags
      end

      def endpoint_status_metric(request,response)
        "#{service_metric(request,:statue)}.#{response.code}"
      end

      def service_error_metric(request,response)
        "#{service_metric(request,:error)}.#{response.class.name.underscore}"
      end
    end

    module In
      include Namespace
      def process(*args, &block)
        return yield unless Helper.http_in_tracable?

        state = D13n::Metric::StreamState.st_get
        state.request = metric_request(args)
        
        trace_options = args.last.is_a?(Hash) ? args.last : {}
        category = trace_options[:category] || :action
        stream_options = create_stream_options(trace_options, category, state)

        t0 = Time.now
        begin
          node = start(state, t0, request)
          response = yield
        ensure
          finish(state, t0, node, request, response)
        end
        return response
      end

      def start(state, t0, request)
        'start'
      end

      def finish(state, t0, node, request, response)
        'finish'
      end
    end

    module Out
      include Namespace

      def process(request, collectable=true)
        state =  D13n::Metric::StreamState.st_get

        return yield unless collectable && Helper.http_out_tracable?

        t0 = Time.now
        begin
          node = start(state, t0, request)
          response = yield
        rescue ServiceNotFound => err
          D13n.logger.error err.message
        rescue Exception => err
          D13n.logger.debug 'Unexpected exception raise while processing HTTP request metric', err
        ensure
          finish(state, t0, node, request, response || err)
        end
        return response
      end

      def start(state, t0, request)
        inject_request_headers(state, request)
        stack = state.traced_stack
        node = stack.push_frame(state, prefix , t0)
        return node
      rescue => e
        D13n.logger.error 'Uncaught exception while start processing HTTP request metric', e
        return nil
      end

      def inject_request_headers(state, request)
        stream = state.current_stream

        state.is_cross_app_caller = true
        if stream
          request[StreamState::D13N_STREAM_HEADER] = state.referring_stream_id || stream.uuid
        end
        request[StreamState::D13N_APP_HEADER] = D13n.app_name        
      end

      def finish(state, t0, node, request, response)
        unless t0
          D13n.logger.error("HTTP request process finished metric without start time. This is probably a bug.")
          return
        end

        unless request
          D13n.logger.error("HTTP request process finished metric without request. This is probably a bug.")
        end
        
        t1 = Time.now
        duration = t1.to_f - t0.to_f
        
        begin
          scoped_metric = get_service_endpoint(request).join('.')
          node.name = scoped_metric if node
          if response
            collect_error_count(request, response) if response.is_a? Exception
            if response.is_a? Net::HTTPResponse
              collect_status_count(request, response)
              collect_request_timing(request, duration)
            end
          else
            collect_request_count(request)
          end
        ensure
          if node
            stack = state.traced_stack
            stack.pop_frame(state, node, scoped_metric, t1)
          end
        end
      rescue ServiceNotFound, EndpointNotFound => e
        D13n.logger.debug "service or endpoind not found while collect HTTP metric:", e.message
      rescue HTTPMetricError => e
        D13n.logger.debug "while collect HTTP metric", e.message
      rescue => e
        D13n.logger.error "Uncaught exception while finishing an HTTP request metric", e
      end

      def collect_request_count(request, count=1, rate=1.0)
        @collector.increment(metric_name('count'), count, sample_rate: rate, tags: http_basic_tags(request))
      end

      def collect_status_count(request, response, count=1, rate=1.0)
        @collector.increment(metric_name('count'), count, sample_rate: rate, tags: http_status_tags(request, response))
      end

      def collect_error_count(request, response, count=1, rate=1.0)
        @collector.increment(metric_name('count'), count, sample_rate: rate, tags: http_error_tags(request, response))
      end

      def collect_request_timing(request, timing, rate=1.0)
        @collector.measure(metric_name('timing'), timing, sample_rate: rate, tags: http_basic_tags(request))
      end
    end

    def self.instance(collector, opts)
      direction = opts[:direction]
      check_direction(direction)
      @instance = new(collector, opts)
      @instance.extend PROCESSOR[direction]
    end

    PROCESSOR = {
      'in' =>  In,
      'out' => Out 
    }

    def initialize(collector, opts)
      @collector = collector
      @opts = opts
      @direction = @opts[:direction]
    end

    def prefix
      "app.http.#{@direction[0]}"
    end

    def metric_name(type)
      "#{prefix}.#{type}"
    end

    def self.check_direction(direction)
      raise InstrumentNameError.new "Wrong request direction #{direction}!" unless PROCESSOR.keys.include?(direction)
    end
  end
end