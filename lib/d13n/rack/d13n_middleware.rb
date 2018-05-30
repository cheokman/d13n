require 'd13n/metric/instrumentation/controller_instrumentation'
module D13n
  module Rack
    class D13nMiddleware
      attr_reader :stream_options, :category
      def initialize(app, options={})
        @app = app
        @category = :middleware
        @target  = self
        @stream_options = {
          :stream_name => build_stream_name
        }
      end

      def build_stream_name
        prefix = ::D13n::Metric::Instrumentation::ControllerInstrumentation::StreamNamer.prefix_for_category(nil, @category)
        "#{prefix}.#{self.class.name}.call"
      end
    end
  end
end