module D13n::Metric::Instrumentation
  module MiddlewareTracing
    STREAM_STARTED_KEY = 'd13n.stream_started'.freeze unless defined?(STREAM_STARTED_KEY)

    def call(env)
      first_middleware = stream_started(env)

      state = D13n::Metric::StreamState.st_get

      begin
        D13n::Metric::Stream.start(state, category, build_stream_options(env, first_middleware))
        state.notify_rack_call(env) if first_middleware

        result = (@target == self) ? traced_call(env) : @target.call(env)

        if first_middleware
          capture_response_attributes(state, result)
        end

        result
      rescue Exception => e
        D13n.logger.error(e)
        raise e
      ensure
        D13n::Metric::Stream.stop(state)
      end
    end

    def capture_response_code(state, result)
      if result.is_a?(Array) && state.current_stream
        state.current_stream.http_response_code = result[0]
      end
    end

    CONTENT_TYPE = 'Content-Type'.freeze unless defined?(CONTENT_TYPE)

    def capture_response_content_type(state, result)
      if result.is_a?(Array) && state.current_stream
        _, headers, _ = result
        state.current_stream.response_content_type = headers[CONTENT_TYPE]
      end
    end

    CONTENT_LENGTH = 'Content-Length'.freeze unless defined?(CONTENT_LENGTH)

    def capture_response_content_length(state, result)
      if result.is_a?(Array) && state.current_stream
        _, headers, _ = result
        state.current_stream.response_content_length = headers[CONTENT_LENGTH]
      end
    end

    def capture_response_attributes(state, result)
      capture_response_code(state, result)
      capture_response_content_type(state, result)
      capture_response_content_length(state, result)
    end
    #
    #  stream_name, apdex_started_at, request
    #

    def build_stream_options(env, first_middleware)
      opts = @stream_options
      opts = merge_first_middleware_options(opts, env) if first_middleware
      opts
    end

    def merge_first_middleware_options(opts, env)
      opts[:apdex_started_at] = parse_request_timestamp(env)
      opts[:request] = ::Rack::Request.new(env) if defined?(::Rack)
      opts
    end

    def parse_request_timestamp(env)
      Time.now.to_i
    end

    def stream_started(env)
      env[STREAM_STARTED_KEY] = true unless env[STREAM_STARTED_KEY]
    end
  end
end