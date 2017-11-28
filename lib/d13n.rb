require 'd13n/version'

module D13n
  class D13nError < StandardError;end
  
  class << self
    def config
      @config ||= D13n::Configuration::Manager.new
    end

    def logger
      @logger ||= D13n::Logger::StartupLogger.instance
    end

    def logger=(log)
      @logger = log
    end

    def opt_state
      D13n::Api::OperationState.opt_get
    end

    def threaded
      Thread.current[:d13n] ||= {}
    end

    def service
      threaded[:service] ||= D13n::Service
    end

    def service=(srv)
      threaded[:service] = srv
    end

    def application
      threaded[:application] ||= self
    end

    def application=(app)
      threaded[:application] = app
    end

    def app_name
      threaded[:app_name] ||= application.name.underscore
    end

    def app_prefix
      threaded[:app_prefix] ||= app_name.upcase
    end
  end
end

require 'd13n/logger'
require 'd13n/configuration'
require 'd13n/application'
require 'd13n/service'


