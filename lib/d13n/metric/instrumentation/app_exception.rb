module D13n::Metric::Instrumentation
  module AppException
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
      class << self
        def exception_with_d13n_instrumentation(*args)
          return exception_without_d13n_instrumentation(*args) if self < D13n::Metric::MetricError

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

        alias exception_without_d13n_instrumentation exception
        alias exception exception_with_d13n_instrumentation
      end

      def exception_with_d13n_instrumentation(*args)
        return exception_without_d13n_instrumentation(*args) if self.class < D13n::Metric::MetricError

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

      alias exception_without_d13n_instrumentation exception
      alias exception exception_with_d13n_instrumentation
    end
  end
end