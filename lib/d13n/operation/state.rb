require 'd13n/operation/traced_stack'
module D13n::Operation
  class StateError < D13n::AxleError;end

  class State
    def self.opt_get
     opt_state_for(Thread.current)
    end

    def self.opt_state_for(thread)
      thread[:d13n_operation_state] ||= new
    end

    attr_reader :traced_stack
    attr_accessor :operation, :request_info
    attr_accessor :tag_hash

    def initialize
      @traced_stack = TracedStack.new
      @sequence = []
    end

    def reset(operation=nil)
      @message = nil
      @traced_stack.clear
      @sequence = []
    end
  end
end