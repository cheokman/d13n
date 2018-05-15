require 'd13n/version'


module D13n
  class Error < StandardError;end
  
  class << self
    def config
      threaded[:config] ||= D13n::Configuration::Manager.new
    end

    def config=(cfg)
      threaded[:config] = cfg
    end

    def logger
      threaded[:logger] ||= D13n::Logger::StartupLogger.instance
    end

    def logger=(log)
     threaded[:logger] = log
    end

    # def opt_state
    #   D13n::Operation::State
    # end

    def threaded
      #@threaded ||= {}
      Thread.current[:d13n] ||= {}
    end

    def reset
      Thread.current[:d13n] = {}
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
      threaded[:app_name] = nil
      threaded[:app_prefix] = nil
    end

    def app_name
      threaded[:app_name] ||= application.name.underscore
    end

    def app_prefix
      threaded[:app_prefix] ||= app_name.upcase
    end

    def idc_name
      config[:'idc.name'] || 'hqidc'
    end

    def idc_env
      config[:'idc.env'] || 'dev'
    end
  end
end

require 'd13n/ext/string'
require 'd13n/logger'
require 'd13n/configuration'
require 'd13n/application'
require 'd13n/service'


