require 'statsd-instrument'
require 'd13n/metric/metrics'
require 'd13n/metric/instrumentation'
module D13n::Metric
  class MetricInitError < MetricError;end
  class MetricArgError < MetricError; end
  class MetricNotFoundError < MetricError; end
  class Manager
    include D13n::Metric::Instrumentation
    def self.start(channel='logger', opt={})
      @instance ||= new(channel, opt)
    end

    def self.instance
      @instance || start
    end

    extend Forwardable

    def_delegators StatsD, :measure, :increment, :gauge, :set

    CHANNELS = ['udp', 'logger', 'null']

    METRIC_MAPPING = {
      'app_state' => AppStateMetric,
      'app_http' => AppHttpMetric,
      'app_database' => AppDatabaseMetric,
      'biz_state' => BizStateMetric
    }

    attr_reader :channel, :backend

    def initialize(channel, opt={})
      self.channel = channel
      @opt = opt
      set_backend
      setup_instrumentation
    end

    def set_backend
      @backend = if @channel == 'udp'
        setup_udp_backend
      elsif @channel == 'logger'
        setup_logger_backend
      else @channel == 'null'
        setup_null_backend
      end
      D13n.logger.info "Using #{@backend.to_s} as channel in metric"
      StatsD.backend = @backend
    end

    def setup_udp_backend
      @host = @opt.fetch(:host, default_host)
      @port = @opt.fetch(:port, default_port)
      @backend_uri = "#{@host}:#{@port}"
      @protocol = @opt.fetch(:protocol, default_protocol)
      StatsD::Instrument::Backends::UDPBackend.new(@backend_uri, @protocol) 
    end

    def setup_logger_backend
      @logger = @opt.fetch(:logger, D13n.logger)
      raise InstrumnetInitError.new "Missing Logger for logger backend" if @logger.nil?
      StatsD::Instrument::Backends::LoggerBackend.new(@logger)
    end

    def setup_null_backend
      StatsD::Instrument::Backends::NullBackend.new
    end

    def channel=(c)
      @channel = c.to_s.downcase
      raise MetricArgError.new("Invalid Instrument channel: #{c}") unless CHANNELS.include?(@channel)
    end

    def metric(type)
      metric_for(type)
    rescue MetricNotFoundError => e
      D13n.logger.error "Instrument Metric Type #{type} Not Found in [#{METRIC_MAPPING.keys.join(',')}]"
      return nil
    end
    
    def metric_for(type)
      expected_metric = METRIC_MAPPING[type.to_s.downcase]
      raise MetricNotFoundError.new "#{type} of metric not found!" if expected_metric.nil?
      expected_metric
    end

    def default_host
      D13n.config[:'service.metric.host'] || 'localhost'
    end

    def default_port
      D13n.config[:'service.metric.port'] || 8125
    end

    def default_protocol
      D13n.config[:'service.metric.protocol'] || :datadog
    end
    
  end
end