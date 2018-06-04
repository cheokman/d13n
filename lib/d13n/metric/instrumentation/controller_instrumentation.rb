require 'd13n/metric/stream'
require 'd13n/metric/stream_state'
module D13n::Metric::Instrumentation
  module ControllerInstrumentation
    def perform_action_with_d13n_stream(*args, &block)
      return yield unless ::D13n::Metric::Helper.http_in_tracable?
      state = D13n::Metric::StreamState.st_get
      state.request = metric_request(args)

      trace_options = args.last.is_a?(Hash) ? args.last : {}
      category = trace_options[:category] || :action
      stream_options = create_stream_options(trace_options, category, state)
      begin
        stream = D13n::Metric::Stream.start(state, category, stream_options)
        
        begin
          yield
        rescue => e
          D13n::Metric::Manager.notice_error(e)
          raise
        end
      ensure
        D13n::Metric::Stream.stop(state)
      end
    end

    protected

    def create_stream_options(trace_options, category, state)
      stream_options = {}
      stream_options[:request] = trace_options[:request]
      stream_options[:request] ||= request if respond_to?(:request) rescue nil
      stream_options[:filtered_params] = trace_options[:params]
      stream_options[:stream_name] = StreamNamer.name_for(nil, self, category, stream_options)
      stream_options
    end

    def metric_request(args)
      opts = args.first
      if opts.respond_to?(:keys) && opts.respond_to?(:[]) && opts[:request]
        opts[:request]
      else self.respond_to?(:request)
        self.request rescue nil
      end
    end

    class StreamNamer
      def self.name_for(stream, trace_obj, category, options={})
        "#{prefix_for_category(stream, category)}.#{namespace(trace_obj, options)}"
      end

      def self.prefix_for_category(stream, category = nil)
        category ||= (stream && stream.category)
        case category
        when :sinatra  then ::D13n::Metric::Stream::SINATRA_PREFIX
        when :middleware then ::D13n::Metric::Stream::MIDDLEWARE_PREFIX
        else "#{category.to_s}"
        end
      end

      def self.namespace(traced_obj, options={})
        return options[:namespace] if options[:namespace]

        kls_name = kls_name(traced_obj, options)
        if options[:name]
          if kls_name
            "#{kls_name}.#{options[:name]}"
          else
            options[:name]
          end
        elsif traced_obj.respond_to?(:d13n_metric_namespace)
          traced_obj.d13n_metric_namespace
        else
          kls_name
        end
      end

      def self.kls_name(trace_obj, options={})
        return options[:class_name] if options[:class_name]

        if (trace_obj.is_a?(Class) || trace_obj.is_a?(Module))
          return nil if trace_obj.name.nil?
          trace_obj.name.underscore
        else
          return nil if trace_obj.class.name.nil?
          trace_obj.class.name.underscore
        end
      end
    end
  end
end