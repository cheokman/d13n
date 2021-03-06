require 'forwardable'

module D13n::Configuration
  def self.value_of(key)
    Proc.new {
      D13n.config[key]
    }
  end

  class Boolean
    def self.===(o)
      TrueClass === o or FalseClass === o
    end
  end

  class DefaultSource
    attr_reader :defaults, :alias

    extend Forwardable
    def_delegators :@defaults, :has_key?, :each, :merge, :delete, :keys, :[], :to_hash

  
    def initialize
      frozen_default
      @defaults = default_values
      @alias = default_alias
    end

    def frozen_default
      D13n::Configuration::DEFAULTS.freeze
    end

    def default_values
      result = {}
      D13n::Configuration::DEFAULTS.each do |key, value|
        result[key] = value[:default]
      end
      result
    end

    def default_alias
      result = {}
      D13n::Configuration::DEFAULTS.each do |key,value|
        result[key] = (value[:alias] || key).to_s
      end
      result
    end

    def self.defaults
      D13n::Configuration::DEFAULTS
    end

    def self.defaults=(default_config)
      D13n::Configuration::DEFAULTS.merge!(default_config)
    end

    def self.config_search_paths
      Proc.new {
        paths = [
            File.join("config", "#{D13n.app_name}.yml"),
            File.join("#{D13n.app_name}.yml")
        ]

        if D13n.service.instance.root
          paths << File.join(D13n.service.instance.root, "config", "#{D13n.app_name}.yml")
          paths << File.join(D13n.service.instance.root, "#{D13n.app_name}.yml")
        end

        if ENV["HOME"]
          paths << File.join(ENV["HOME"], ".#{D13n.app_name}", "#{D13n.app_name}.yml")
          paths << File.join(ENV["HOME"], "#{D13n.app_name}.yml")
        end
        paths
      }
    end

    def self.config_path
      Proc.new {
        found_path = D13n.config[:config_search_paths].detect do |file|
          File.expand_path(file) if File.exist? file
        end
        found_path || ""
      }
    end

    def self.transform_for(key)
      default_settings = D13n::Configuration::DEFAULTS[key]
      default_settings[:transform] if default_settings
    end

    def self.convert_to_list(value)
      case value
      when String
        value.split(/\s*,\s*/)
      when Array
        value
      else
        raise ArgumentError.new("Config value '#{value}' couldn't be turned into a list.")
      end
    end
  end

  DEFAULTS = {
      :app_name => {
        :default => Proc.new{"#{D13n.app_name}"},
        :public => true,
        :type => String,
        :allowed_from_server => false,
        :description => 'Define Application Name'
      },
      :port => {
          :default => 3000,
          :public => true,
          :type => Integer,
          :description => 'Define service port'
      },
      :host => {
          :default => '0.0.0.0',
          :public => true,
          :type => String,
          :description => 'Define service host'
      },
    #
    # Log config
    #
      :log_level => {
          :default => 'info',
          :public => true,
          :type => String,
          :description => 'Sets the level of detail of log messages. Possible log levels, in increasing verbosity, are: <code>error</code>, <code>warn</code>, <code>info</code> or <code>debug</code>.'
      },
      :log_file_path => {
          :default => 'stdout',
          :public => true,
          :type => String,
          :description => 'Defines a path to the log file, excluding the filename.'
      },
      :log_file_name => {
          :default => Proc.new{"#{D13n.app_name}.log"},
          :public => true,
          :type => String,
          :description => 'Defines a name for the log file.'
      },
      #
      # YAML file Config
      #
      :config_path => {
          :default => DefaultSource.config_path,
          :public => true,
          :type => String,
          :description => 'Path to <b>application.yml</b>. If undefined, the agent checks the following directories (in order): <b>config/application.yml</b>, <b>application.yml</b>, <b>$HOME/.d13n/application.yml</b> and <b>$HOME/application.yml</b>.'
      },
      :config_search_paths => {
          :default => DefaultSource.config_search_paths,
          :public => false,
          :type => Array,
          :allowed_from_server => false,
          :description => "An array of candidate locations for the service\'s configuration file."
        },
      :'metric.channel.type' => {
          :default => 'logger',
          :public => true,
          :type => String,
          :allowed_from_server => true,
          :description => 'Metric Channel Type.'
      },
      :'metric.app.http.in.apdex_t' => {
        :default => 300,
        :public => true,
        :type => Integer,
        :allowed_from_server => true,
        :description => 'Metric HTTP IN Apdex Config Value.'
      },
      :'metric.app.http.in.tracable' => {
        :default => true,
        :public => true,
        :type => D13n::Configuration::Boolean,
        :description => 'Metric HTTP IN trace enable switch'
      },
      :'metric.app.http.in.sinatra.enable' => {
      :default => true,
      :public => true,
      :type => D13n::Configuration::Boolean,
      :description => 'enable http in trace for sinatra'
      },
      :'metric.app.http.in.sinatra.auto_middleware.enable' => {
        :default => true,
       :public => true,
       :type => D13n::Configuration::Boolean,
       :description => 'enable sinatra auto load middleware'
      },
      :'metric.app.http.out.tracable' => {
        :default => true,
        :public => true,
        :type => D13n::Configuration::Boolean,
        :allowed_from_server => true,
        :description => "Metric HTTP OUT trace enable switch"
      }
   }
end
