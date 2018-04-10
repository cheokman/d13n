require 'd13n/metric/http_clients/http_helper'
module D13n::Metric::HTTPClients
  class NetHTTPClientRequest
    def initialize(connection, request)
      @connection = connection
      @request = request
    end

    def type
      'Net::HTTP'
    end

    def host
      if hostname = self['host']
        hostname.split(':').first
      else
        @connection.address
      end
    end

    def [](key)
      @request[key]
    end

    def []=(key, value)
      @request[key] = value
    end

    def uri
      case @request.path
      when /^https?:\/\//
        URI(@request.path)
      else
        scheme = @connection.use_ssl? ? 'https' : 'http'
        URI("#{scheme}://#{@connection.address}:#{@connection.port}#{@request.path}")
      end
    end
  end

  class NetHTTPClientResponse
    def initialize(connection, response)
      @response = response
    end

    def uri
      return @response.uri unless @response.uri.nil?
      nil
    end

    def status_code
      @response.code
    end
  end
end