# encoding: utf-8
#require 'd13n/api/operation_state'
require 'logger'
require 'singleton'
require 'd13n/logger/log_once'
require 'd13n/logger/memory_logger'
require 'd13n/logger/null_logger'
module D13n
  class Logger
    class SilenceLogger
      def fatal(*args); end
      def error(*args); end
      def warn(*args);  end
      def info(*args);  end
      def debug(*args); end

      def method_missing(method, *args, &blk)
        nil
      end
    end

    def initialize(root="STDOUT", override_logger=nil)
      @root = root
      
      create_logger(@root, override_logger)
      set_log_level!
      set_log_format!
      
      gather_startup_logs
    end

    def info(*msgs, &blk)
      format_and_send(:info, msgs, &blk)
    end

    def warn(*msgs, &blk)
      format_and_send(:warn, msgs, &blk)
    end

    def error(*msgs, &blk)
      format_and_send(:error, msgs, &blk)
    end

    def fatal(*msgs, &blk)
      format_and_send(:fatal, msgs, &blk)
    end

    def debug(*msgs, &blk)
      format_and_send(:debug, msgs, &blk)
    end

    def log_formatter=(formatter)
      @log.formatter = formatter
    end

    def log_exception(level, e, backtrace_level=level)
      @log.send(level, "%p: %s" % [ e.class, e.message ])
      @log.send(backtrace_level) do
        backtrace = backtrace_from_exception(e)
        if backtrace
          "Debugging backtrace:\n" + backtrace.join("\n  ")
        else
          "No backtrace available."
        end
      end
    end

    def formatter
      @log.formatter
    end

    private

    def backtrace_from_exception(e)
      return caller.drop(5) if e.is_a?(SystemStackError)

      e.backtrace
    end

    def find_or_create_file_path(path_setting, root)
      for abs_path in [ File.expand_path(path_setting),
                        File.expand_path(File.join(root, path_setting)) ] do
        if File.directory?(abs_path) || (Dir.mkdir(abs_path) rescue nil)
          return abs_path[%r{^(.*?)/?$}]
        end
      end
      nil
    end

    def format_and_send(level, *msgs, &block)
      if block
        if @log.send("#{level}?")
          msgs = Array(block.call)
        else
          msgs = []
        end
      end

      msgs.flatten.each do |item|
        case item
        when Exception then log_exception(level, item, :debug)
        else @log.send(level, item)
        end
      end
      nil
    end
    
    LOG_LEVELS = {
        "debug" => ::Logger::DEBUG,
        "info"  => ::Logger::INFO,
        "warn"  => ::Logger::WARN,
        "error" => ::Logger::ERROR,
        "fatal" => ::Logger::FATAL,
    }

    def self.log_level_for(level)
        LOG_LEVELS.fetch(level.to_s.downcase, ::Logger::INFO)
    end

    def set_log_level!
        @log.level = self.class.log_level_for(::D13n.config[:log_level])
    end

    def log_stdout?
      D13n.config[:log_file_path].upcase == "STDOUT"
    end

    def create_log_to_file(root)
      path = find_or_create_file_path(::D13n.config[:log_file_path], root)
      if path.nil?
        @log = ::Logger.new(STDOUT)
        warn("Error creating log directory #{::D13n.config[:log_file_path]}, using standard out for logging.")
      else
        file_path = "#{path}/#{::D13n.config[:log_file_name]}"
        begin
          @log = ::Logger.new(file_path)
        rescue => e
          @log = ::Logger.new(STDOUT)
          warn("Failed creating logger for file #{file_path}, using standard out for logging.", e)
        end
      end
    end

    def create_logger(root,override_logger)
      if !override_logger.nil?
        @log = override_logger
      elsif ::D13n.config[:log_level] == :silence
        create_silence_logger
      else
        if log_stdout?
          @log = ::Logger.new(STDOUT)
        else
          create_log_to_file(root)
        end
      end
    end

    def set_log_format!
      @prefix = log_stdout? ? "** [#{D13n.config[:app_name].capitalize}]" : ''
      @log.formatter = 
      if log_format == 'json'
        Proc.new do |severity, timestamp, progname, msg|
          log_data = tag_hash.merge({
            app: D13n.config.app_name,
            ts: timestamp.strftime("%F %H:%M:%S %z"),
            pid: $$,
            severity: severity,
            request_id: request_id
          })
          if msg.respond_to?(:to_hash)
            log_data.merge!(msg.to_hash)
          else
            log_data.merge!({message: msg})
          end 
          "#{log_data.to_json}\n"
        end
      else
        Proc.new do |severity, timestamp, progname, msg|
          "#{@prefix}[#{timestamp.strftime("%F %H:%M:%S %z")} (#{$$})] #{severity} #{request_id} : #{msg}\n"
        end
      end
    end

    def log_format
      ::D13n.config[:log_format]
    end

    def state
      D13n::Metric::StreamState.st_get
    end
    
    def request_id
      @request_info = state.request_info || {}
      @request_info['request_id'] || '-'
    end

    def tag_hash
      state.tag_hash || {}
    end

    def create_silence_logger
      @log = SilenceLogger.new
    end

    def gather_startup_logs
      StartupLogger.instance.dump(self)
    end

    class StartupLogger < MemoryLogger
      include Singleton
    end
  end
end