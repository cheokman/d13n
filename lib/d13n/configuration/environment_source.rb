module D13n::Configuration
  class EnvironmentSource < DottedHash
    SUPPORTED_PREFIXES = Proc.new {/^#{D13n.app_name}_/i}
    SPECIAL_CASE_KEYS  = [
          "#{D13n.app_prefix}_LOG"  # read by set_log_file
        ]

    attr_accessor :type_map

    def initialize
      set_log_file
      set_config_file

      @type_map = {}

      DEFAULTS.each do |config_setting, value|
        self.type_map[config_setting] = value[:type]
      end

      set_values_from_app_environment_variables
    end

    def set_log_file
      env_log = "#{D13n.app_prefix}_LOG"
      if ENV[env_log]
        if ENV[env_log].upcase == 'STDOUT'
          self[:log_file_path] = self[:log_file_name] = 'STDOUT'
        else
          self[:log_file_path] = File.dirname(ENV[env_log])
          self[:log_file_name] = File.basename(ENV[env_log])
        end
      end
    end

    def set_config_file
      env_config = "#{D13n.app_prefix}_CONFIG"
      self[:config_path] = ENV[env_config] if ENV[env_config]
    end

    def set_values_from_app_environment_variables
      app_env_var_keys = collect_app_environment_variable_keys

      app_env_var_keys.each do |key|
        next if SPECIAL_CASE_KEYS.include?(key.upcase)
        set_value_from_app_environment_variable(key)
      end
    end

    def set_value_from_app_environment_variable(key)
      config_key = convert_environment_key_to_config_key(key)
      set_key_by_type(config_key, key)
    end

    def set_key_by_type(config_key, environment_key)
      value = ENV[environment_key]
      type = self.type_map[config_key]

      if type == String
        self[config_key] = value
      elsif type == Integer
        self[config_key] = value.to_i
      elsif type == Float
        self[config_key] = value.to_f
      elsif type == Symbol
        self[config_key] = value.to_sym
      elsif type == Array
        self[config_key] = value.split(/\s*,\s*/)
      elsif type == D13n::Configuration::Boolean
        if value =~ /false|off|no/i
          self[config_key] = false
        elsif value != nil
          self[config_key] = true
        end
      else
        D13n.logger.info("#{environment_key} does not have a corresponding configuration setting (#{config_key} does not exist).")
        self[config_key] = value
      end
    end

    def convert_environment_key_to_config_key(key)
      stripped_key = key.gsub(SUPPORTED_PREFIXES.call, '').downcase.to_sym
    end


    def collect_app_environment_variable_keys
      ENV.keys.select { |key| key.match(SUPPORTED_PREFIXES.call) }
    end
  end
end
