require 'd13n/version'

module D13n
  class D13nError < StandardError;end
  
  class << self
    def config
      @config ||= {}
    end

    def config
      @config ||= D13n::Configuration::Manager.new
    end

    def logger
      @logger ||= D13n::Logger::StartupLogger.instance
    end

    def logger=(log)
      @logger = log
    end

    # def opt_state
    #   D13n::Api::OperationState.opt_get
    # end

    def threaded
      Thread.current[:d13n] ||= {}
    end

    def service
      threaded[:service] ||= nil
    end

    def service=(srv)
      threaded[:service] = srv
    end

    def application
      threaded[:application] ||= nil
    end

    def application=(app)
      threaded[:application] = app
    end
  end
end
require 'd13n/logger'
require 'd13n/configuration'
require 'd13n/application'
require 'd13n/service'