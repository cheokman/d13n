module D13n::Metric::HTTPClients
  module HTTPHelper
    def service
      Helper.service_for(uri)
    end

    def endpoint
      Helper.endpoint_for(uri)
    end

    def service_endpoint
      [service, endpoint].join('.')
    end
  end
end