module D13n::Metric
  class Stream
    module StreamTracerHelpers
      module Namer
        def prefix
          "app.http.i"
        end
  
        def metric_name(type)
          "#{prefix}.#{type}"
        end
  
        def stream_basic_tags(metric_data)
          tags = []
          tags << "idc:#{D13n.idc_name}"
          tags << "env:#{D13n.idc_env}"
          tags << "app:#{D13n.app_name}"
          tags << "name:#{metric_data[:name]}"
          tags << "uuid:#{metric_data[:uuid]}"
          tags << "stream_id:#{metric_data[:referring_stream_id] || metric_data[:uuid]}"
          tags << "type:#{metric_data[:referring_stream_id].nil? ? 'stream' : 'span'}"
          tags
        end
  
        def stream_duration_tags(metric_data)
          tags = stream_basic_tags(metric_data)
          tags << "time:duration"
          tags
        end
  
        def stream_exclusive_tags(metric_data)
          tags = stream_basic_tags(metric_data)
          tags << "time:exclusive"
          tags
        end
  
        def stream_request_tags(metric_data)
          tags = stream_basic_tags(metric_data)
          tags
        end

        def stream_http_response_code_tags(metric_data)
          tags = stream_basic_tags(metric_data)
          tags << "response:code"
          tags << "code:#{metric_data[:http_response_code]}"
          tags
        end

        def stream_http_response_content_type_tags(metric_data)
          tags = stream_basic_tags(metric_data)
          tags << "response:type"
          tags << "type:#{metric_data[:http_response_content_type]}"
          tags
        end

        def stream_http_response_content_length_tags(metric_data)
          tags = stream_basic_tags(metric_data)
          tags << "response:length"
          tags
        end
  
        def stream_error_tags(metric_data, error)
          tags = stream_basic_tags(metric_data)
          tags << "error:#{error.is_a?(Class) ? error.name : error.class.name}"
          tags
        end

        def stream_apdex_tags(metric_data)
          tags = stream_basic_tags(metric_data)
          tags << "apdex_zone:#{metric_data[:apdex_perf_zone]}"
          tags
        end
      end

      include Namer
      extend self

      def collect_duration_metric(collector, state, timing, metric_data, rate=1.0)
        collector.measure(metric_name("timing"), timing, sample_rate: rate, tags: stream_duration_tags(metric_data))
      end

      def collect_exclusive_metric(collector, state, timing, metric_data, rate=1.0)
        collector.measure(metric_name("timing"), timing, sample_rate: rate, tags: stream_exclusive_tags(metric_data))
      end

      def collect_apdex_metric(collector, state, metric_data, count=1,rate=1.0)
        collector.increment(metric_name("count"), count, sample_rate: rate, tags: stream_apdex_tags(metric_data))
      end

      def collect_repsonse_code_metric(collector, state, metric_data, count=1,  rate=1.0)
        collector.increment(metric_name("count"), count, sample_rate: rate, tags: stream_http_response_code_tags(metric_data))
      end

      def collect_response_content_type_metric(collector, state, metric_data, count=1,  rate=1.0)
        collector.increment(metric_name("count"), count, sample_rate: rate, tags: stream_http_response_content_type_tags(metric_data))
      end

      def collect_response_content_length_metric(collector, state, gauge, metric_data, rate=1.0)
        collector.gauge(metric_name("gauge"), gauge, sample_rate: rate, tags: stream_http_response_content_length_tags(metric_data))
      end

      def collect_response_metric(collector, state, metric_data)
        collect_repsonse_code_metric(collector, state, metric_data)
        collect_response_content_type_metric(collector, state, metric_data)
        collect_response_content_length_metric(collector, state, metric_data[:http_response_content_length], metric_data)
      end

      def collect_error_metric(collector, state, error, metric_data, count=1, rate=1.0 )
        collector.increment(metric_name('count'), count, sample_rate: rate, tags: stream_error_tags(metric_data, error))
      end

      def collect_errors_metric(collector, state, metric_data)
        errors = metric_data[:errors]

        errors.each do |error|
          collect_error_metric(collector, state, error, metric_data)
        end
      end

      def collect_metrics(state, metric_data)
        collector = D13n::Metric::Manager.instance
        collect_duration_metric(collector, state, metric_data[:duration], metric_data)
        collect_exclusive_metric(collector, state, metric_data[:exclusive], metric_data)
        collect_apdex_metric(collector, state, metric_data)
        collect_response_metric(collector, state, metric_data)
        collect_errors_metric(collector, state, metric_data) if metric_data[:error]
      end
    end
  end
end