module D13n::Application
  module ClassMethods
    def self.extended(descendant)
      D13n.application = descendant
    end

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

    # def opt_state
    #   D13n::Api::OperationState.opt_get
    # end

    def service
      D13n.service
    end

    def application
      D13n.application
    end

    def app_name
      D13n.app_name
    end

    def app_prefix
      D13n.app_prefix
    end

    def reset
      @config = nil
      @logger = nil
    end
  end
end