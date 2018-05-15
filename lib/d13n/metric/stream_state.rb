require 'd13n/metric/stream/traced_stack'
module D13n::Metric
  class StateError < D13n::Error;end
  class StreamState
    def self.st_get
     st_state_for(Thread.current)
    end

    def self.st_state_for(thread)
      thread[:d13n_stream_state] ||= new
    end

    attr_reader :traced_span_stack
    attr_accessor :operation, :request_info
    attr_accessor :tag_hash
    attr_accessor :current_stream
    attr_accessor :request
    attr_accessor :referring_stream_id, :is_cross_app_caller

    def initialize
      @traced_span_stack = D13n::Metric::Stream::TracedStack.new
      @sequence = []
      @current_stream = nil
      @referring_stream_id = nil
      @is_cross_app_caller = false
    end

    def reset(stream=nil)
      @message = nil
      @traced_stack.clear
      @sequence = []
      @current_stream = stream
      @is_cross_app_caller = false
    end
  end
end