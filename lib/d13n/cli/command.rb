require 'optparse'
require 'pp'

$LOAD_PATH << "#{File.dirname(__FILE__)}/.."

module D13n
  module Cli
    class Command
      class CommandFailure < StandardError
        attr_reader :options
        def initialize message, opt_parser=nil
          super message
          @options = opt_parser
        end
      end

      def initialize(args)
        if Hash === args
          args.each do |k, v| 
            instance_variable_set "@#{k}", v.to_s if v
          end
        else

          @options = options do |opts|
            opts.on("-h", "Show this help") {  raise CommandFailure, opts.to_s }
          end
          raise CommandFailure, @options.to_s if args.empty?
          @leftover = @options.parse(args)
        end
      rescue OptionParser::ParseError => e
        raise CommandFailure.new(e.message, @options)
      end

      @commands = []
      def self.inherited(subclass)
        @commands << subclass
      end

      cmds = cmds = File.expand_path(File.join(File.dirname(__FILE__), 'commands', '*.rb'))
      Dir[cmds].each { |command| require command }

      def self.run
        @command_names = @commands.map{ |c| c.command}

        extra = []

        options = ARGV.options do |opts|
          script_name = File.basename($0)
          opts.banner = "Usage: #{script_name} [ #{ @command_names.join(" | ")} ] [options]"
          opts.separator "use '#{script_name} <command> -h' to see detailed command options"
          opts
        end
        extra = options.order!
        command = extra.shift

        if command.nil?
          STDOUT.puts "No command provided"
          STDOUT.puts options.to_s
        elsif !@command_names.include?(command)
          STDOUT.puts "Unrecognized command: #{command}"
          STDOUT.puts options
        else
          command_class = @commands.find{ |c| c.command == command}
          command_class.new(extra).run
        end
      rescue OptionParser::InvalidOption => e
        raise CommandFailure.new(e.message)
      end

      def run
        raise NotImplementedError, 'Command class must be able to #run!'
      end

    end
  end
end