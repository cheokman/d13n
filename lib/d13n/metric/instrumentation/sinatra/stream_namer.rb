module D13n::Metric::Instrumentation::Sinatra
  module StreamNamer
    extend self

    SINATRA_ROUTE = 'sinatra.route'
    UNKNOWN = 'unknown'.freeze
    def for_route(env, request)
      env[SINATRA_ROUTE]
    end

    def initial_stream_name(request)
      stream_name(UNKNOWN, request)
    end

    ROOT = '.'.freeze


    def stream_name(route_text, request)
      verb = http_verb(request)

      route_text = route_text.source if route_text.is_a?(Regexp)
      name = route_text.gsub(%r{^[/^\\A]*(.*?)[/\$\?\\z]*$}, '\1')
      name = ROOT if name.empty?
      name = "#{verb}#{name}" unless verb.nil?
      name
    rescue => e
      ::D13n.logger.debug("#{e.class} : #{e.message} - Error encountered trying to identify Sinatra transaction name")
      UNKNOWN
    end

    def http_verb(request)
      request.request_method if request.respond_to?(:request_method)
    end
  end
end