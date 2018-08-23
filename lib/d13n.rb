require 'd13n/version'


module D13n
  class Error < StandardError;end
  
  class << self
    def dry_run?
      threaded[:dry_run] ||= false
    end

    def enable_dry_run
      threaded[:dry_run] = true
    end

    def config
      threaded[:config] ||= D13n::Configuration::Manager.new
    end

    def config=(cfg)
      threaded[:config] = cfg
    end

    def logger
      @logger ||= if dry_run?
        D13n::Logger::NullLogger.instance
      else
        D13n::Logger::StartupLogger.instance
      end
    end

    def logger=(log)
     @logger = log
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
      #threaded[:service] ||= D13n::Service
      @service ||= D13n::Service
    end

    def service=(srv)
      #threaded[:service] = srv
      @service = srv
    end

    def application
      @application ||= self
    end

    def application=(app)
      @application = app
      @app_name = nil
      @app_prefix = nil
    end

    def app_name
      application.name.underscore
    end

    def app_prefix
      app_name.upcase
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
require 'd13n/metric'
require 'd13n/logger'
require 'd13n/configuration'
require 'd13n/application'
require 'd13n/service'


