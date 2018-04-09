module D13n::Metric
  class InstrumentNameError < MetricError; end
  class Base
    attr_reader :prefix

    def prefix
      raise NotImplementedError
    end

    def process(&block)
      raise NotImplementedError
    end
  end
end