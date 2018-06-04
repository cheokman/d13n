require 'd13n/metric/stream/stream_tracer_helpers'
module D13n::Metric
  class Stream
    module SpanTracerHelpers
      MAX_ALLOWED_METRIC_DURATION = 1_000_000_000
      include StreamTracerHelpers::Namer


      extend self

      # def prefix
      #   "app.http.i"
      # end

      # def metric_name(type)
      #   "#{prefix}.#{type}"
      # end

      # def stream_basic_tags(metric_data)
      #   tags = []
      #   tags << "idc:#{D13n.idc_name}"
      #   tags << "env:#{D13n.idc_env}"
      #   tags << "app:#{D13n.app_name}"
      #   tags << "name:#{metric_data[:name]}"
      #   tags << "uuid:#{metric_data[:uuid]}"
      #   tags << "stream_id:#{metric_data[:referring_stream_id] || metric_data[:uuid]}"
      #   tags << "type:#{metric_data[:referring_stream_id].nil? ? 'stream' : 'span'}"
      #   tags
      # end

      # def stream_duration_tags(metric_data)
      #   tags = stream_basic_tags(metric_data)
      #   tags << "time:duration"
      #   tags
      # end

      # def stream_exclusive_tags(metric_data)
      #   tags = stream_basic_tags(metric_data)
      #   tags << "time:exclusive"
      #   tags
      # end

      # def stream_request_tags(metric_data)
      #   tags = stream_basic_tags(metric_data)
      #   tags
      # end

      # def stream_http_response_code_tags(metric_data)
      #   tags = stream_basic_tags(metric_data)
      #   tags << "response:code"
      #   tags << "code:#{metric_data[:http_response_code]}"
      #   tags
      # end

      # def stream_http_response_content_type_tags(metric_data)
      #   tags = stream_basic_tags(metric_data)
      #   tags << "response:type"
      #   tags << "type:#{metric_data[:http_response_content_type]}"
      #   tags
      # end

      # def stream_http_response_content_length_tags(metric_data)
      #   tags = stream_basic_tags(metric_data)
      #   tags << "response:length"
      #   tags
      # end

      # def stream_error_tags(metric_data, error)
      #   tags = stream_basic_tags(metric_data)
      #   tags << "error:#{error.is_a?(Class) ? error.name : error.class.name}"
      #   tags
      # end

      # def stream_apdex_tags(metric_data)
      #   tags = stream_basic_tags(metric_data)
      #   tags << "apdex_zone:#{metric_data[:apdex_perf_zone]}"
      #   tags
      # end
      
      def collect_span_duration_timing(collector, state, name, timing, metric_data, options, rate=1.0)
        collector.measure(metric_name("timing"), timing, sample_rate: rate, tags: stream_duration_tags(metric_data))
      end

      def collect_span_exclusive_timing(collector, state, name, timing, metric_data, options, rate=1.0)
        collector.measure(metric_name("timing"), timing, sample_rate: rate, tags: stream_exclusive_tags(metric_data))
      end

      def collect_span_request_count(collector, state, name, metric_data, options, count = 1, rate = 1.0)
        collector.increment(metric_name("count"), count, sample_rate: rate, tags: stream_request_tags(metric_data))
      end

      def collect_span_metrics(state, first_name, duration, exclusive, metric_data, options)
        collector = D13n::Metric::Manager.instance
        collect_span_duration_timing(collector, state, first_name, duration, metric_data, options)
        collect_span_exclusive_timing(collector, state, first_name, exclusive, metric_data, options)
        collect_span_request_count(collector, state, first_name, metric_data, options)
      end

      def trace_header(state, t0)
        stack = state.traced_span_stack
        stack.push_frame(state, :span_tracer, t0)
      end

      def trace_footer(state, t0, first_name, expected_frame, options, t1=Time.now.to_i)
        if expected_frame
          stack = state.traced_span_stack
          frame = stack.pop_frame(state, expected_frame, first_name, t1)
          duration, exclusive = get_timings(t0, t1, frame)
          metric_data = {:exclusive => exclusive}
          get_metric_data(state, t0, t1, metric_data)
        
          if duration < MAX_ALLOWED_METRIC_DURATION
            if duration < 0
              D13n.logger.warn("metric_duration_negative:#{first_name} Metric #{first_name} has negative duration: #{duration} s")
            end

            if exclusive < 0
              D13n.logger.warn("metric_exclusive_negative: #{first_name} Metric #{first_name} has negative exclusive time: duration = #{duration} s, child_time = #{frame.children_time}")
            end
           
            collect_span_metrics(state, first_name, duration, exclusive, metric_data, options)
          else
            D13n.logger.warn("too_huge_metric:#{first_name}, Ignoring metric #{first_name} with unacceptably large duration: #{duration} s")
          end
          
        end
      end

      def get_timings(t0, t1, frame)
        duration = t1 - t0
        exclusive = duration - frame.children_time
        [duration, exclusive]
      end

      def get_metric_data(state, t0, t1, metric_data)
        stream = state.current_stream
        stream.generate_default_metric_data(state, t0, t1, metric_data)
      end
    end
  end
end