require 'd13n/metric/stream_state'
require 'd13n/metric/instrumentation/middleware_tracing'
require 'd13n/rack/d13n_middleware'
module D13n
  module Rack
    class MetricMiddleware < D13nMiddleware
      include D13n::Metric::Instrumentation::MiddlewareTracing
      
      def self.enabled?
        !D13n.config[:'metric.app.http.in.tracable']
      end
  
      def traced_call(env)
        @app.call(env)
      end
    end
  end
end