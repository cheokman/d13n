require 'securerandom'

module Rack
  class RequestId
    X_REQUEST_ID = "X-Request-Id".freeze

    def initialize(app, opts = {})
      @app = app
    end

    def call(env)
      env['HTTP_X_REQUEST_ID'] = make_request_id(env[X_REQUEST_ID]||env['HTTP_X_REQUEST_ID'])
      @app.call(env).tap {|_status, headers, _body| headers[X_REQUEST_ID] = env['HTTP_X_REQUEST_ID'] }
    end

    private
    def make_request_id(request_id)
      if request_id.nil?
        internal_request_id
      else
        request_id
      end
    end

    def internal_request_id
      SecureRandom.hex(16)
    end
  end
end