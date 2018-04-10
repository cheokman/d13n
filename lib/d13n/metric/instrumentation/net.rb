
D13n::Metric::Instrumentation::Conductor.direct do
  named :net_http

  depend_on do
    defined?(Net) && defined?(Net::HTTP)
  end

  performances do
    D13n.logger.info 'Installing Net instrumentation'
    require 'd13n/metric/http_clients/net_http_wrappers'
  end

  performances do
    class Net::HTTP
      def request_with_axle_instrumentation(request, *args, &block)
        return request_without_axle_instrumentation(request, *args, &block) unless started?
        wrapped_request = D13n::Metric::HTTPClients::NetHTTPClientRequest.new(self, request)
        manager = D13n::Metric::Manager.instance
        metric = manager.metric(:app_http)
        
        if metric.nil?
          D13n.logger.info "Null intrumentation metric class and ignore collection"
          return request_without_axle_instrumentation(request, *args, &block) 
        end

        metric.instance(manager, direction: 'out').process(wrapped_request) do
          request_without_axle_instrumentation(request, *args, &block)
        end
      end

      alias request_without_axle_instrumentation request
      alias request request_with_axle_instrumentation
    end
  end
end