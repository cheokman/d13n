require 'd13n/metric/stream/traced_span_stack'
module D13n::Metric
  class StateError < D13n::Error;end
  class StreamState

    D13N_STREAM_HEADER = 'X-D13n-Stream-ID'
    D13N_APP_HEADER = 'X-D13n-App'
    REQUEST_ID_HEADER = 'HTTP_X_REQUEST_ID'

    def self.st_get
      st_state_for(Thread.current)
    end

    def self.st_state_for(thread)
      thread[:d13n_stream_state] ||= new
    end

    def self.request_info
      st_get.request_info
    end

    def self.default_metric_data
      state = st_get
      stream = state.current_stream
      if stream
        stream.default_metric_data
      else
        {}
      end
    end

    attr_reader :traced_span_stack
    attr_accessor :request_info
    attr_accessor :tag_hash
    attr_accessor :current_stream
    attr_accessor :request
    attr_accessor :referring_stream_id, :is_cross_app_caller

    def initialize
      @traced_span_stack = D13n::Metric::Stream::TracedSpanStack.new
      @current_stream = nil
      @referring_stream_id = nil
      @is_cross_app_caller = false
    end

    def reset(stream=nil)
      @traced_span_stack.clear
      @current_stream = stream
      @is_cross_app_caller = false
    end

    def notify_rack_call(request)
      notify_call(request)
    end

    def notify_call(request)
      save_referring_stream_id(request)
    end

    def save_referring_stream_id(request)
      @referring_stream_id = request[D13N_STREAM_HEADER] if request[D13N_STREAM_HEADER]
    end

    def clear_referring_stream_id()
      @referring_stream_id = nil
    end
  end
end