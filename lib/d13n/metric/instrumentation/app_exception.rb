module D13n::Metric::Instrumentation
  module AppException
    def self.included(descendance)
      descendance.include(InstanceMethods)
      descendance.extend(ClassMethods)
    end

    module ClassMethods
      def metric_error_inherated?
        !!(self < D13n::Metric::MetricError)
      end

      def exception_with_d13n_instrumentation(*args)
        return exception_without_d13n_instrumentation(*args) unless metric_error_inherated?

        manager = D13n::Metric::Manager.instance
        metric = manager.metric(:app_state)
        
        if metric.nil?
          D13n.logger.info "Null intrumentation metric class and ignore collection"
          return exception_without_d13n_instrumentation(*args)
        end

        metric.instance(manager, {type: 'exception', at: 'runtime', src: 'app'}).process do
          exception_without_d13n_instrumentation(*args)
        end
      end
    end

    module InstanceMethods
      def exception_with_d13n_instrumentation(*args)
        self.class.exception_with_d13n_instrumentation(*args)
      end
    end

    module_function
    def enable?
      D13n.config[:'metric.app.state.exception.enable'] == 'true' || D13n.config[:'metric.app.state.exception.enable'] == true
    end
  end
end

D13n::Metric::Instrumentation::Conductor.direct do
  named :app_exception

  depend_on do
    D13n::Metric::Instrumentation::AppException.enable?
  end

  depend_on do
    defined?(D13n) && defined?(D13n::Error)
  end

  performances do
    D13n.logger.info 'Installing Application Exeception instrumentation'
  end

  performances do
    class D13n::Error
      include D13n::Metric::AppException
      class << self
        alias exception_without_d13n_instrumentation exception
        alias exception exception_with_d13n_instrumentation
      end

      alias exception_without_d13n_instrumentation exception
      alias exception exception_with_d13n_instrumentation
    end
  end
end