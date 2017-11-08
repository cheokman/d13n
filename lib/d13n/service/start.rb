require 'config-kit'

module D13n
  class Service
    module Start
      # def log_startup
      #   log_environment
      #   log_service_name
      # end

      # def log_environment
      #   D13n.logger.info "Environment: #{D13n.env}"
      # end

      # def log_service_name
      #   D13n.logger.info "Service: #{D13n.config.app_name}"
      # end

      # def log_version_and_pid
      #   D13n.logger.debug "#{D13n.config.app_name} Service #{D13n.version}(D13n:#{D13n::VERSION::STRING}) Initialized: pid = #{$$}"
      # end

      # def query_server_for_configuration
      #   begin
      #     #
      #     # TODO: Config Kit may enhance configurator
      #     #
      #     ConfigKit.config.url = D13n.config[:ck_url] || D13n.config[:'service.config_kit.url']
      #     config_data = ConfigKit::Manager.get(D13n.config.app_name)
      #   rescue ConfigKit::Client::ConfigKitReadError => e
      #     D13n.logger.error "Config Kit reads server error. #{e.message}"
      #     raise D13n::ServiceStartError.new(e.message) if config_server_raise_on_failure?
      #   rescue Exception => e
      #     D13n.logger.error "Unknown Config Kit error. #{e.message}"
      #     D13n.logger.debug e
      #     raise D13n::ServiceStartError.new(e.message) if config_server_raise_on_failure?
      #   end
      #   #
      #   # TODO: Empty to raise exception
      #   #
      #   return if config_data.nil? || config_data.empty?

      #   D13n.logger.debug "Server provided config: #{config_data.inspect}"

      #   server_config = D13n::Configuration::ServerSource.build(config_data)
      #   D13n.config.replace_or_add_config(server_config)
      # end

      # def config_server_raise_on_failure?
      #   D13n.config[:'config_server.raise_on_failure']
      # end

      # def start_metric_manager
      #   begin
      #     channel = D13n.config[:metric_channel_type] || D13n.config[:'metric.channel.type']
      #     Api::Metric::Manager.start(channel)
      #   rescue Exception => e
      #     D13n.logger.error "Unknown Instrument Manager error. #{e.message}"
      #   end
      # end

      def start_api_service
        @started = true
        Object.const_get("#{D13n.application.name}::Api::Service").run!(@service_conf)
      end
    end
  end
end