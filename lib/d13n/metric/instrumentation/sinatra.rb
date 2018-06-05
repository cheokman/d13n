require 'd13n/metric/instrumentation/controller_instrumentation'
require 'd13n/metric/instrumentation/sinatra/stream_namer'
require 'd13n/rack/metric_middleware'
D13n::Metric::Instrumentation::Conductor.direct do
  named :sinatra

  depend_on do
    D13n.config[:'metric.app.http.in.sinatra.enable'] &&
    defined?(::Sinatra) && defined?(::Sinatra::Base) &&
    Sinatra::Base.private_method_defined?(:dispatch!) &&
    Sinatra::Base.private_method_defined?(:process_route) &&
    Sinatra::Base.private_method_defined?(:route_eval)
  end

  performances do
    D13n.logger.info 'Installing Sinatra instrumentation'
  end

  performances do
    ::Sinatra::Base.class_eval do
      include D13n::Metric::Instrumentation::Sinatra
      alias dispatch_without_d13n_instrumentation dispatch!
      alias dispatch! dispatch_with_d13n_instrumentation

      alias process_route_without_d13n_instrumentation process_route
      alias process_route process_route_with_d13n_instrumentation

      alias route_eval_without_d13n_instrumentation route_eval
      alias route_eval route_eval_with_d13n_instrumentation
      
    end
  end

  performances do
    if Sinatra::Base.respond_to?(:build)
      require 'd13n/rack/metric_middleware'

      ::Sinatra::Base.class_eval do
        class << self
          alias build_without_d13n_instrumentation build
          alias build build_with_d13n_instrumentation
        end
      end
    else
      D13n.logger.info("Skipping auto-injection of middleware for Sinatra - require Sinatra 1.2.1+")
    end
  end

  performances do
    if defined?(::SinatraWebsocket) &&
       defined?(::Sinatra::Request) &&
       Sinatra::Request.respond_to?(:websocket)
      ::Sinatra::Base.class_eval do
        class << self
          alias websocket_without_d13n_instrumentation websocket
          alias websocket websocket_with_d13n_instrumentation
        end
      end
    end
  end
end

module D13n::Metric::Instrumentation
  module Sinatra
    include D13n::Metric::Instrumentation::ControllerInstrumentation
    
    def self.included(descendance)
      descendance.extend(ClassMethods)
    end

    module ClassMethods
      def d13n_middlewares
        middlewares = []
        if D13n::Rack::MetricMiddleware.enabled?
          middlewares << D13n::Rack::MetricMiddleware
        end
        middlewares
      end

      def websocket_with_d13n_instrumentation(*args, &block)
        websocket_without_d13n_instrumentation(*args, &block)
      end

      def build_with_d13n_instrumentation(*args, &block)
        if auto_middleware_enable?
          d13n_middlewares.each do |middleware_kls|
            try_to_use(self, middleware_kls)
          end
        end

        build_without_d13n_instrumentation(*args, &block)
      end

      private

      def auto_middleware_enable?
        D13n.config[:'metric.app.http.in.sinatra.auto_middleware.enable']
      end
  
      
      def try_to_use(app, clazz)
        if app.middleware.nil?
          D13n.logger.debug("Failed to use middle for middleware missing in app")
          return nil
        end
        has_middleware = app.middleware.any? { |info| info[0] == clazz }
        app.use(clazz) unless has_middleware
      end
    end

    def process_route_with_d13n_instrumentation(*args, &block)
      begin
        env["d13n.last_route"] = args[0]
      rescue => e
        D13n.logger.debug("Failed determining last route in Sinatra", e)
      end

      process_route_without_d13n_instrumentation(*args, &block)
    end

    def route_eval_with_d13n_instrumentation(*args, &block)
      begin
        stream_name = StreamNamer.for_route(env, request)
        
        unless stream_name.nil?
          ::D13n::Metric::Stream.set_default_stream_name("#{self.class.name}.#{stream_name}", :sinatra)
        end
      rescue => e
        D13n.logger.debug("Failed during route_eval to set stream name", e)
      end

      route_eval_without_d13n_instrumentation(*args, &block)
    end

    def dispatch_with_d13n_instrumentation
      request_params = get_request_params
      name = StreamNamer.initial_stream_name(request)
      filter_params = get_filter_parames(request_params)
      perform_action_with_d13n_stream(:category => :sinatra,
                                      :name => name,
                                      :params => filter_params) do
        dispatch_and_notice_errors_with_d13n_instrumentation
      end
    end

    def dispatch_and_notice_errors_with_d13n_instrumentation
      dispatch_without_d13n_instrumentation
    ensure
      had_error = env.has_key?('sinatra.error')
      ::D13n::Metric::Manager.notice_error(env['sinatra.error']) if had_error
    end

    def get_request_params
      begin
        @request.params
      rescue => e
        D13n.logger.debug("Failed to get params from Rack request.", e)
      end
    end

    def get_filter_parames(request_params)
      request_params
    end
  end
end