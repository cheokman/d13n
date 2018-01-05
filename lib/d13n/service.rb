require 'd13n/ext/string'
require 'd13n/service/start'
module D13n
  class Service
    class ServiceError < D13nError; end
    class ServiceStartError < ServiceError; end

    include Start
    class << self
      def instance
        @instance ||= new
      end

      def run!(opts)
        D13n.service.instance.init_service(opts)
        D13n.service.instance.start
      end

      def app_class
        @app_kls ||= Object.const_get(name.split("::").first)
      end

      def inherited(descendant)
        raise ServiceError, "You cannot have more than one D13n::Service" if D13n.service && descendant == D13n::Service
        descendant.app_class.extend Application::ClassMethods
        D13n.service = descendant
      end
    end

    attr_reader :service_conf, :env, :service_prefix
    def initialize()
      @started=false
      @app_prefix = D13n.service.class.name.underscore.upcase
    end

    def init_service(opts)
      determine_service_conf(opts)
      determine_env(opts)

      config_service(opts)

      if D13n.logger.is_startup_logger?
        D13n.logger = D13n::Logger.new(root,opts.delete(:logger))
      end
    end

    def determine_service_conf(opt)
      @service_conf ||= {}
      @service_conf[:port] = opt.fetch(:port, 3000)
      @service_conf[:bind] = opt.fetch(:host, 'localhost')
    end

    def determine_env(opt)
      @env = opt.fetch(:env, default_env).to_s
    end

    def config_service(opts)
      config_file_path = D13n.config[:config_path]
      D13n.config.replace_or_add_config(D13n::Configuration::YamlSource.new(config_file_path, env))
    end

    def started?
      @started
    end

    def root
      @root = ENV['SERVICE_ROOT'] || '.'
    end

    def settings
      D13n.config.to_collecter_hash
    end

    def start
      return if started?
      log_startup
      start_api_service
    end
    
  private
    def default_env
      ENV["#{D13n.app_prefix}_ENV"] || ENV['RACK_ENV'] || 'development'
    end
  end
end