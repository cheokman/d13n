require 'd13n/metric/stream_state'
require 'd13n/metric/instrumentation/controller_instrumentation'
module D13n::Metric
  class Stream

    SINATRA_PREFIX = 'controller.sinatra'.freeze

    attr_accessor :state, :started_at

    def self.st_current
      StreamState.tl_get.current_stream
    end

    def self.set_default_stream_name(name, category = nil, node_name = nil)
      stream = st_current
      name = stream.make_stream_name(name, category)
      stream.name_last_frame(node_name || name)
      stream.set_default_stream_name(name, category)
    end

    def self.start(state, category, options)
      category ||= :controller
      stream = start_new_stream(state, category, options)
      stream
    rescue => e
      D13n.logger.error("Exception during Stream.start", e)
      nil
    end

    def self.start_new_stream(state, category, options)
      stream = Stream.new(category, options)
      state.reset(stream)
      stream.state = state
      stream.start(state)
      stream
    end

    def self.stop(state, ended_time=Time.now)
    end

    def self.notice_error(exception, options={})
      state = D13n::Metric::StreamState.st_get
      stream = state.current_stream
      if stream
        stream.notice_error(exception, options)
      end
    end

    def initialize(category, options)
      @frame_stack = []

      @category = category
      @started_at = Time.now.to_i

      @default_name = options[:stream_name]
      
      @apdex_started_at = options[:apdex_started_at] || @started_at

      @ignore_apdex = false
      @ignore_this_stream = false
    end

    def start(state)
      @frame_stack.push D13n::Metric::Stream::SpanTraceHelpers.trace_helper(state, @started_at)
    end

    def make_stream_name(name, category=nil)
      namer = Instrumentation::ControllerInstrumentation::StreamNamer
      "#{namer.prefix_for_category(self, category)}.#{name}"
    end

    def set_default_stream_name(name, category)
      @default_name = name
      @category = category if category
    end
    
    def name_last_frame(name)
      @frame_stack.last.name = name
    end

    def notice_error(exception, options={})
      if @exceptions[exception]
        @exceptions[exception].merge! options
      else
        @exceptions[exception] = options
      end
    end
  end
end