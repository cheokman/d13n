module D13n::Metric
  class AppStateMetric < Base
    module Namespace
      def gem_metric_tags(gem_info)
        tags = []
        tags << "idc:#{Helper.idc_name}"
        tags << "env:#{Helper.idc_env}"
        tags << "app:#{Helper.app_name}"
        tags << "gem:#{gem_info[0]}"
        tags << "version:#{gem_info[1]}"
        tags
      end

      def exception_metric_tags(exception, opts)
        tags = []
        tags << "idc:#{Helper.idc_name}"
        tags << "env:#{Helper.idc_env}"
        tags << "app:#{Helper.app_name}"
        tags << "name:#{exception.class.name}"
        tags << "at:#{opts.fetch(:at, 'runtime')}"
        tags << "src:#{opts.fetch(:src, 'app')}"
        tags
      end
    end

    module GemProcessor
      include Namespace

      def process
        load_gem_spec.each do |g| 
          collect_gem_gauge(g)
        end
      end

      def load_gem_spec
        Gem.loaded_specs.inject({}) {
          |m, (n,s)| m.merge(n => s.version)
        }
      end

      def collect_gem_gauge(named_gem,gauge=1, rate=1.0)
        @collector.gauge(metric_name('gauge'), gauge, sample_rate:rate, tags: gem_metric_tags(named_gem))
      end
    end

    module ExceptionProcessor
      include Namespace

      def process
        return yield unless Helper.exception_tracable?

        begin
          exception = yield
        ensure
          finish(exception)
        end
        return exception
      end

      def finish(exception)
        collect_exception_count(exception, @opts)
      end

      def collect_exception_count(exception, opts, count=1, rate=1.0)
        @collector.increment(metric_name('count'), count, sample_rate: rate, tags: exception_metric_tags(exception,opts))
      end
    end

    PROCESSOR = {
      'gem' => GemProcessor,
      'exception' => ExceptionProcessor
    }

    def self.check_type(type)
      raise InstrumentNameError.new "Wrong request process type #{type}!" unless PROCESSOR.has_key?(type)
    end

    def self.instance(collector, opts)
      type = opts[:type]
      check_type(type)
      @instance = new(collector, opts)
      @instance.extend PROCESSOR[type]
    end

    def initialize(collector, opts)
      @collector = collector
      @opts = opts
      @type = @opts[:type]
    end

    def metric_name(type)
      "#{prefix}.#{type}"
    end

    def prefix
      "app.state.#{@type}"
    end
  end
end