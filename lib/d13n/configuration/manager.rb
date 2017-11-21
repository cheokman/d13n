require 'd13n/configuration/mask_defaults'
require 'd13n/configuration/dotted_hash'
require 'd13n/configuration/default_source'
require 'd13n/configuration/environment_source'
require 'd13n/configuration/yaml_source'
require 'd13n/configuration/server_source'
require 'd13n/configuration/manual_source'
module D13n::Configuration
  class Manager
    def [](key)
      @cache[key]
    end

    def has_key?(key)
      @cache.has_key?(key)
    end

    def keys
      @cache.keys
    end

    def key(value)
      @cache.key(value)
    end

    def alias_key_for(value)
      alias_for(key(value))
    end

    def alias_for(key)
      @alias_cache[key]
    end

    def initialize
      reset_to_defaults
      @callbacks = Hash.new { |hash, key| hash[key] = [] }
    end

    def remove_config_type(sym)
      source = case sym
      when :environment   then @environment_source
      when :server        then @server_source
      when :manual        then @manual_source
      when :yaml          then @yaml_source
      when :default       then @default_source
      end

      remove_config(source)
    end

    def remove_config(source)
      case source
      when EnvironmentSource  then @environment_source   = nil
      when ServerSource       then @server_source        = nil
      when ManualSource       then @manual_source        = nil
      when YamlSource         then @yaml_source          = nil
      when DefaultSource      then @default_source       = nil
      end

      reset_cache
      reset_alias
      invoke_callbacks(:remove, source)
      log_config(:remove, source)
    end

    def replace_or_add_config(source)
      source.freeze

      invoke_callbacks(:add, source)
      case source
      when EnvironmentSource  then @environment_source   = source
      when ServerSource       then @server_source        = source
      when ManualSource       then @manual_source        = source
      when YamlSource         then @yaml_source          = source
      when DefaultSource      then @default_source       = source
      else
        D13n.logger.warn("Invalid config format; config will be ignored: #{source}")
      end

      reset_cache
      reset_alias
      log_config(:add, source)
    end

    def source(key)
      config_stack.each do |config|
        if config.respond_to?(key.to_sym) || config.has_key?(key.to_sym)
          return config
        end
      end
    end

    def fetch(key)
      config_stack.each do |config|
        next unless config
        accessor = key.to_sym

        if config.has_key?(accessor)
          evaluated = evaluate_procs(config[accessor])
          begin
            return apply_transformations(accessor, evaluated)
          rescue
            next
          end
        end
      end
      nil
    end

    def apply_transformations(key, value)
      if transform = transform_from_default(key)
        begin
          transform.call(value)
        rescue => e
          D13n.logger.error("Error applying transformation for #{key}, pre-transform value was: #{value}.", e)
          raise e
        end
      else
        value
      end
    end

    def transform_from_default(key)
      D13n::Configuration::DefaultSource.transform_for(key)
    end

    def evaluate_procs(value)
      if value.respond_to?(:call)
        instance_eval(&value)
      else
        value
      end
    end

    # Generally only useful during initial construction and tests
    def reset_to_defaults
      @environment_source   = EnvironmentSource.new
      @server_source        = nil
      @manual_source        = nil
      @yaml_source          = nil
      @default_source       = DefaultSource.new
      reset_cache
      reset_alias
    end

    def reset_cache
      @cache = Hash.new {|hash,key| hash[key] = self.fetch(key) }
    end

    def reset_alias
      @alias_cache = @default_source.default_alias
    end

    def log_config(direction, source)
      D13n.logger.debug do
        "Updating config (#{direction}) from #{source.class}. Results: #{flattened.inspect}"
      end
    end

    def register_callback(key, &proc)
      @callbacks[key] << proc
      proc.call(@cache[key])
    end

    def invoke_callbacks(direction, source)
      return unless source
      source.keys.each do |key|

        if @cache[key] != source[key]
          @callbacks[key].each do |proc|
            if direction == :add
              proc.call(source[key])
            else
              proc.call(@cache[key])
            end
          end
        end
      end
    end

    def flattened
      config_stack.reverse.inject({}) do |flat,layer|
        thawed_layer = layer.to_hash.dup
        thawed_layer.each do |k,v|
          begin
            thawed_layer[k] = instance_eval(&v) if v.respond_to?(:call)
          rescue => e
            D13n.logger.debug("#{e.class.name} : #{e.message} - when accessing config key #{k}")
            thawed_layer[k] = nil
          end
          thawed_layer.delete(:config)
        end
        flat.merge(thawed_layer.to_hash)
      end
    end

    def apply_mask(hash)
      MASK_DEFAULTS. \
        select {|_, proc| proc.call}. \
        each {|key, _| hash.delete(key) }
      hash
    end

    def to_collector_hash
      DottedHash.new(apply_mask(flattened)).to_hash.delete_if do |k, v|
        default = DEFAULTS[k]
        if default
          default[:exclude_from_reported_settings]
        else
          false
        end
      end
    end

    def app_name
      D13n.config[:app_name]
    end

    private

    def config_stack
      stack = [@environment_source,
               @server_source,
               @manual_source,
               @yaml_source,
               @default_source]

      stack.compact!
      stack
    end

  end
end