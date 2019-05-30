module D13n::Configuration
  class ServerSource < DottedHash
    SERVICE_PREFIXES = /^service/i
    PROPERTY_PREFIXES = /^property/i
    IDC_PREFIXES = /^idc/i
    CLIENT_PREFIXES = /^client/i
    JURISDICTION_PREFIXES = /^jurisdiction/i

    attr_accessor :type_map

    def initialize(connect_reply)
      #filter_keys(connect_reply)
      @type_map = {}

      DEFAULTS.each do |config_setting, value|
        self.type_map[config_setting] = value[:type]
      end

      super(connect_reply)
    end

    def set_keys_by_type()
      self.keys.each do |key|
        set_key_by_type(key)
      end
    end

    def set_key_by_type(config_key)
      value = self[config_key]
      type = self.type_map[config_key]

      if type == String
        self[config_key] = value.to_s
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
        D13n.logger.info("#{config_key} does not have a corresponding configuration setting (#{config_key} does not exist).")
        self[config_key] = value
      end
    end

    def self.build(connect_reply)
      instance = new(connect_reply)
      self.filter_keys(instance)
      instance
    end

    def self.filter_keys(instance)
      instance.delete_if do |key, _|
        s_key = key.to_s
        if s_key.match(SERVICE_PREFIXES) || s_key.match(PROPERTY_PREFIXES) || s_key.match(IDC_PREFIXES) || s_key.match(CLIENT_PREFIXES) || s_key.match(JURISDICTION_PREFIXES)
          false
        else
          setting_spec = DEFAULTS[key.to_sym]
          if setting_spec
            if setting_spec[:allowed_from_server]
              instance.set_key_by_type(key)
              false # it's allowed, so don't delete it
            else
              D13n.logger.warn("Ignoring server-sent config for '#{key}' - this setting cannot be set from the server")
              true # delete it
            end
          else
            D13n.logger.debug("Ignoring unrecognized config key from server: '#{key}'")
            true
          end
        end
      end
    end
  end
end
