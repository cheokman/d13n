require 'd13n/metric/stream_state'
require 'd13n/metric/instrumentation/controller_instrumentation'
require 'd13n/metric/stream/stream_tracer_helpers'
require 'd13n/metric/stream/span_tracer_helpers'
require 'securerandom'

module D13n::Metric
  class Stream

    SINATRA_PREFIX = 'controller.sinatra'.freeze
    MIDDLEWARE_PREFIX = 'controller.middleware'.freeze

    WEB_TRANSACTION_CATEGORIES   = [:controller, :uri, :rack, :sinatra].freeze

    APDEX_S = 'S'.freeze
    APDEX_T = 'T'.freeze
    APDEX_F = 'F'.freeze

    attr_accessor :state, :started_at, :uuid
    attr_accessor :http_response_code,
                  :response_content_type,
                  :response_content_length, :frame_stack

    def self.st_current
      StreamState.st_get.current_stream
    end

    def self.set_default_stream_name(name, category = nil, node_name = nil)
      stream = st_current
      name = stream.make_stream_name(name, category)
      stream.name_last_frame(node_name || name)
      stream.set_default_stream_name(name, category)
    end

    def self.start(state, category, options)
      category ||= :controller
      stream = state.current_stream

      if stream 
        stream.create_nested_stream(state, category, options)
      else
        stream = start_new_stream(state, category, options)
      end
      stream
    rescue => e
      D13n.logger.error("Exception during Stream.start", e)
      nil
    end

    def self.start_new_stream(state, category, options)
      stream = new(category, options)
      state.reset(stream)
      stream.state = state
      stream.start(state)
      stream
    end

    def self.stop(state, ended_time=Time.now.to_f)
      stream = state.current_stream
      if stream.nil?
        D13n.logger.error("Failed during Stream.stop because there is no current stream")
        return
      end

      nested_frame = stream.frame_stack.pop
      if stream.frame_stack.empty?
        stream.stop(state, ended_time, nested_frame)
        state.reset
      else
        nested_name = nested_stream_name(nested_frame.name)
        begin
          D13n::Metric::Stream::SpanTracerHelpers.trace_footer(state, nested_frame.start_time.to_f, nested_name, nested_frame, {})
        rescue => e
          D13n.logger.debug "Error in trace_footer #{e}"
        end
      end

      #:stream_stopped
    end

    def self.notice_error(exception, options={})
      state = D13n::Metric::StreamState.st_get
      stream = state.current_stream
      if stream
        stream.notice_error(exception, options)
      end
    end

    def self.apdex_bucket(duration, failed, apdex_t)
    
      case
      when failed
        :apdex_f
      when duration <= apdex_t
        :apdex_s
      when duration <= (4 * apdex_t)
        :apdex_t
      else
        :apdex_f
      end
    end

    def self.nested_stream_name(name)
      name
    end

    def initialize(category, options)
      @frame_stack = []

      @category = category
      @started_at = Time.now.to_f

      @default_name = options[:stream_name]
      
      @apdex_started_at = options[:apdex_started_at] || @started_at

      @ignore_apdex = false
      @ignore_this_stream = false

      @uuid = nil
      @exceptions = {}
    end

    def start(state)
      @frame_stack.push D13n::Metric::Stream::SpanTracerHelpers.trace_header(state, @started_at)
      name_last_frame @default_name
    end

    def stop(state, ended_time, outermost_frame)
      trace_options = {}
      if @has_children
        name = self.class.nested_stream_name(outermost_frame.name)
      else
        name = @frozen_name
      end

      D13n::Metric::Stream::SpanTracerHelpers.trace_footer(state, @started_at.to_f, name, outermost_frame, trace_options, ended_time.to_f)
      duration = ended_time - @started_at
      exclusive = duration - outermost_frame.children_time
      commit!(state, exclusive, ended_time) unless @ignore_this_stream
    end

    def commit!(state, exclusive, ended_time)
      @metric_data = {:exclusive => exclusive}
      collect_metric_data(state, @metric_data, ended_time)
      collect_metrics(state, @metric_data)
    end

    def apdex_t
      stream_specific_apdex_t || D13n.config[:apdex_t]
    end

    def stream_specific_apdex_t
      key = "web_stream_apdex_t.#{@frozen_name}".to_sym
      D13n.config[key]
    end

    def collect_metrics(state, metric_data)
      StreamTracerHelpers.collect_metrics(state, metric_data)
    end

    def collect_metric_data(state, metric_data, ended_time = Time.now.to_f)
      total_duration = ended_time - @apdex_started_at
      action_duration = ended_time - @started_at.to_f

      # collect_apdex_metric(total_duration, action_duration, apdex_t)
      generate_metric_data(state, metric_data, @started_at, ended_time)
    end

    # def collect_apdex_metric(total_duration, action_duration, current_apdex_t)
    #   apdex_bucket_global = apdex_bucket(total_duration, current_apdex_t)
    #   apdex_bucket_stream = apdex_bucket(action_duration, current_apdex_t)
    # end

    def default_metric_data
      metric_data = {
        :name => @frozen_name || @default_name,
        :uuid => uuid,
        :error => false
      }

      generate_error_data(metric_data)
      metric_data[:referring_stream_id] = @state.referring_stream_id if @state.referring_stream_id
      metric_data
    end

    def generate_error_data(metric_data)
      if had_error?
        metric_data.merge!({
         :error => true,
         :errors => @exceptions 
        })
      end
    end

    def generate_default_metric_data(state, started_at, ended_time, metric_data)
      duration = ended_time - started_at
      
      metric_data.merge!(default_metric_data)
      metric_data.merge!({
        :type => :request,
        :started_at => started_at,
        :duration => duration,
      })
      metric_data
    end

    def generate_metric_data(state, metric_data, started_at, ended_time)
      duration = ended_time - started_at
      metric_data ||= {}
      generate_default_metric_data(state, started_at, ended_time, metric_data)
      append_apdex_perf_zone(duration, metric_data)
      append_web_response(@http_response_code, @response_content_type, @response_content_length, metric_data) if recording_web_transaction?
      metric_data
    end

    def had_error?
      !@exceptions.empty?
    end

    def had_exception_affecting_apdex?
      # all exceptions are affecting
      had_error?  
    end

    def apdex_bucket(duration, current_apdex_t)
      self.class.apdex_bucket(duration, had_exception_affecting_apdex?, current_apdex_t)
    end

    def append_apdex_perf_zone(duration, metric_data)
      bucket = apdex_bucket(duration, apdex_t)

      return unless bucket
 
      bucket_str = case bucket
      when :apdex_s then APDEX_S
      when :apdex_t then APDEX_T
      when :apdex_f then APDEX_F
      else nil
      end

      metric_data[:apdex_perf_zone] = bucket_str if bucket_str
    end

    def append_web_response(http_response_code,response_content_type,response_content_length,metric_data)
      return if http_response_code.nil?

      metric_data[:http_response_code] = http_response_code
      metric_data[:http_response_content_type] = response_content_type
      metric_data[:http_response_content_length] = response_content_length
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

    def create_nested_stream(state, category, options)
      @has_children = true

      @frame_stack.push D13n::Metric::Stream::SpanTracerHelpers.trace_header(state, Time.now.to_f)
      name_last_frame(options[:stream_name])

      set_default_stream_name(options[:stream_name], category)
    end

    def set_default_stream_name(name, category)
      return if name_frozen?
      @default_name = name
      @category = category if category
    end

    def name_frozen?
      @frozen_name ? true : false
    end

    def name_last_frame(name)
      @frame_stack.last.name = name
    end

    def recording_web_transaction?
      web_category?(@category)
    end

    def web_category?(category)
      WEB_TRANSACTION_CATEGORIES.include?(category)
    end

    def get_id
      uuid
    end

    def uuid
      return @uuid if @uuid
      request_info = StreamState.request_info
      @uuid = (request_info.nil? || request_info["request_id"].nil?) ? SecureRandom.hex(16) : request_info["request_id"]
      @uuid
    end
  end
end