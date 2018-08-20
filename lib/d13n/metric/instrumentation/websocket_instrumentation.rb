require 'd13n/metric/stream'
require 'd13n/metric/stream_state'
module D13n::Metric::Instrumentation
  module WebSocketInstrumentation
    def perform_websocket_with_d13n_stream(*args, &block)
      state = D13n::Metric::StreamState.st_get
      category = :websocket

      trace_options = args.last.is_a?(Hash) ? args.last : {}
      stream_options = create_stream_options(trace_options, category, state)

      begin
        stream = D13n::Metric::Stream.start(state, category, stream_options)

        begin
          yield
          update_stream_data(state)
        rescue => e
          D13n::Metric::Manager.notice_error(e)
          raise
        ensure
          D13n::Metric::Stream.stop(state)
        end
      end
    end

    protected
    def create_stream_options(trace_options, categroy, state)
      stream_options = {}
      stream_options[:stream_name]
      stream_options
    end

    def update_stream_data(state)
      stream = state.current_stream
      stream.http_response_code = 200
      stream.request_content_length = request.delete(:request_content_length)
      stream.response_content_type = "websocket"
      stream.response_content_length = request.delete(:response_content_length)
    end
  end
end