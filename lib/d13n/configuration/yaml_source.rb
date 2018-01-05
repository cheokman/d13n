require 'yaml'
module D13n::Configuration
  class YamlSource < DottedHash
    attr_accessor :file_path, :failures

    def initialize(path,env)
      config = {}
      @failures = []

      begin
        @file_path = validate_config_file(path)
        return unless @file_path

        D13n.logger.info("Reading configuration from #{path} (#{Dir.pwd})")
        raw_file = File.read(@file_path)
        erb_file = process_erb(raw_file)
        config   = process_yaml(erb_file, env, config, @file_path)
      rescue ScriptError, StandardError => e
        log_failure("Failed to read or parse configuration file at #{path}", e)
      end

      super(config, true)
    end

    protected

    def validate_config_file(path)
      expanded_path = File.expand_path(path)

      if path.empty? || !File.exist?(expanded_path)
        return
      end

      expanded_path
    end

    def process_erb(file)
      begin
        file.gsub!(/^\s*#.*$/, '#')

        ERB.new(file).result(binding)
      rescue Exception => e
        log_failure("Failed ERB processing configuration file. This is typically caused by a Ruby error in <% %> templating blocks in your axle.yml file.", e)
      ensure

      end
    end

    def process_yaml(file, env, config, path)
     if file
      confighash = YAML.load(file)
      unless confighash.key?(env)
        log_failure("Config file at #{path} doesn't include a '#{env}' section!")
      end
      config = confighash[env] || {}
      end

      config
    end

    def log_failure(*messages)
      D13n.logger.error(*messages)
      @failures << messages
    end
  end
end