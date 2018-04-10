module D13n::Metric::Instrumentation
  module Exception
    def self.included(descendance)
      descendance.include(InstanceMethods)
      descendance.extend(ClassMethods)
    end
    module ClassMethods
      def d13n_error_inherated?
        !!(self < D13n::Error)
      end

      def exception_with_d13n_instrumentation(*arg)
        return exception_without_d13n_instrumentation(*arg) if d13n_error_inherated?

        manager = D13n::Metric::Manager.instance
        metric = manager.metric(:app_state)
        
        if metric.nil?
          D13n.logger.info "Null intrumentation metric class and ignore collection"
          return exception_without_d13n_instrumentation(*arg)
        end

        metric.instance(manager, {type: 'exception', at: 'runtime', src:'others'}).process do
          exception_without_d13n_instrumentation(*arg)
        end
        return exception_without_d13n_instrumentation(*arg)
      end
    end

    module InstanceMethods
      def exception_with_d13n_instrumentation(*arg)
        self.class.exception_with_d13n_instrumentation(*arg)
      end
    end

    module_function
    def enable?
      D13n.config[:'metric.app.state.exception.enable'] == 'true' || D13n.config[:'metric.app.state.exception.enable'] == true
    end
  end
end


D13n::Metric::Instrumentation::Conductor.direct do
  named :exception

  depend_on do
    D13n::Metric::Instrumentation::Exception.enable?
  end

  performances do
    D13n.logger.info 'Installing Exeception instrumentation'
  end

  performances do
    class StandardError
      class << self
        alias exception_without_d13n_instrumentation exception
        alias exception exception_with_d13n_instrumentation
      end
      alias exception_without_d13n_instrumentation exception
      alias exception exception_with_d13n_instrumentation
    end
  end
end