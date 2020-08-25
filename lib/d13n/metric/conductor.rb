require 'd13n/metric'
module D13n::Metric::Instrumentation
  module Conductor
    module_function
    @concerts = []

    def direct(&block)
      concert = Performance.new
      concert.instance_eval(&block)

      if concert.name
        seen_names = @concerts.map { |c| c.name }.compact
        if seen_names.include?(concert.name)
          D13n.logger.warn("Refusing to re-register Performance block with name '#{concert.name}'")
          return @concerts
        end
      end

      @concerts << concert
    end

    def perform!
      @concerts.each do |concert|
        if concert.ready?
          concert.perform
        end
      end
    end

    def concert_by_name(name)
      @concerts.find { |c| c.name == name }
    end

    def performed?(name)
      concert = concert_by_name(name)
      concert && concert.performed
    end

    def concerts
      @concerts
    end

    def concerts=(new_concerts)
      @concerts = new_concerts
    end

    def clear
      @concerts = []
    end

    class Performance
      attr_reader :performed
      attr_accessor :name

      def perform!
        @performed = true
      end

      attr_reader :dependences

      def initialize
        @dependences = []
        @performances = []
        @name = nil
      end

      def ready?
        !performed and check_dependences
      end

      def perform
        @performances.each do |p|
          begin
            p.call
          rescue => e
            D13n.logger.error("Error while setting up #{self.name} instrumentation:", e)
            break
          end
        end
      ensure
        perform!
      end

      def depend_on(&block)
        @dependences << block
      end

      def check_dependences
        return false unless allowed_by_config? && dependences

        dependences.all? do |score|
          begin
            score.call
          rescue => e
            D13n.logger.error("Error while checking #{self.name}:", e)
            false
          end
        end
      end

      def allowed_by_config?
        return true if self.name.nil?

        key = "instrumentation.#{self.name}.disable".to_sym

        if (D13n.config[key] == true)
          D13n.logger.debug("Not setting up #{self.name} instrumentation for configuration #{key}")
          false
        else
          true
        end
      end

      def named(new_name)
        self.name = new_name
      end

      def performances(&block)
        @performances << block
      end
    end
  end
end