module D13n::Application
  module ClassMethods
    def config
      @config ||= D13n.config
    end

    def config=(cfg)
      @config = cfg
    end

    def logger
      @logger ||= D13n.logger
    end

    def logger=(log)
      @logger = log
    end

    def default_source
      D13n::Configuration::DefaultSource.defaults
    end

    def default_source=(default_config)
      D13n::Configuration::DefaultSource.defaults = default_config
    end

    def opt_state
      D13n::Api::OperationState.opt_get
    end

    def service
      Service
    end
  end
end