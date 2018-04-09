require 'spec_helper'
require 'd13n/metric'
describe D13n::Metric::Manager do
  describe '.new' do
    before :each do
      allow_any_instance_of(described_class).to receive(:set_backend)
      allow_any_instance_of(described_class).to receive(:setup_instrumentation)
      @channel = 'udp'
      @opt = {a: 1, b: 2}
      
    end

    it 'assign channel' do
      @instance = described_class.new(@channel, @opt)
      expect(@instance.channel).to be_eql @channel
    end

    it 'assign opt' do
      @instance = described_class.new(@channel, @opt)
      expect(@instance.instance_variable_get(:@opt)).to be_eql @opt
    end

    it 'set_backend called' do
      expect_any_instance_of(described_class).to receive(:set_backend).once
      @instance = described_class.new(@channel, @opt)
    end
  end

  describe '#set_backend' do
    before :each do
      allow_any_instance_of(described_class).to receive(:setup_instrumentation)
    end
    context 'when udp channel' do
      before :all do
        @emtpy_opt = {}
        @host = 'statsd'
        @port = 1234
        @protocol = :statsd
        @opt = {host: @host, port: @port}
        @default_host = 'localhost'
        @default_port = 8123
        @default_protocol = :datadog
      end

      context 'with empty opt' do
        before :each do
          allow_any_instance_of(described_class).to receive(:default_host).and_return(@default_host)
          allow_any_instance_of(described_class).to receive(:default_port).and_return(@default_port)
          @instance = described_class.new('udp')
        end

        it 'set udp backend' do
          expect(@instance.backend).to be_kind_of StatsD::Instrument::Backends::UDPBackend
        end

        it 'set default host' do
          expect(@instance.backend.host).to be_eql @default_host
        end

        it 'set default port' do
          expect(@instance.backend.port).to be_eql @default_port
        end

        it 'set default protocol' do
          pp @instance.backend.implementation
          expect(@instance.backend.implementation).to be_eql @default_protocol
        end

        it 'assign StatsD backend' do
          expect(StatsD.backend).to be_eql(@instance.backend)
        end
      end

      context 'with opt' do
        before :each do
          @instance = described_class.new('udp', @opt.merge({protocol: @protocol}))
        end

        it 'set udp backend' do
          expect(@instance.backend).to be_kind_of StatsD::Instrument::Backends::UDPBackend
        end

        it 'set host' do
          expect(@instance.backend.host).to be_eql @host
        end

        it 'set port' do
          expect(@instance.backend.port).to be_eql @port
        end

        it 'set protocol' do
          expect(@instance.backend.implementation).to be_eql @protocol
        end
      end
    end

    context 'when logger channel' do
      before :all do
        @logger = ::Logger.new(STDOUT)
      end

      context 'with empty opt' do
        before :each do
          @instance = described_class.new('logger')
        end

        it 'set logger backend' do
          expect(@instance.backend).to be_kind_of StatsD::Instrument::Backends::LoggerBackend
        end

        it 'set default D13n logger' do
          expect(@instance.backend.logger).to be_eql D13n.logger
        end
      end

      context 'with opt' do
        before :each do
          @instance = described_class.new('logger', logger: @logger)
        end

        it 'set logger backend' do
          expect(@instance.backend).to be_kind_of StatsD::Instrument::Backends::LoggerBackend
        end

        it 'set logger' do
          expect(@instance.backend.logger).to be_eql @logger
        end
      end
    end

    context 'when null channel' do
      before :each do
        @instance = described_class.new('null')
      end

      it 'set null backend' do
        expect(@instance.backend).to be_kind_of StatsD::Instrument::Backends::NullBackend
      end
    end
  end

  describe '#channel=' do
    before :each do
      allow_any_instance_of(described_class).to receive(:set_backend)
      allow_any_instance_of(described_class).to receive(:setup_instrumentation)
    end

    context 'wrong channel' do
      it 'raise error for nil channel' do
        expect {described_class.new(nil)}.to raise_error D13n::Metric::MetricArgError
      end

      it 'raise error for unsupported channel' do
        expect {described_class.new('fake')}.to raise_error D13n::Metric::MetricArgError
      end
    end

    context 'support string with any cases' do
      it 'does not raise error for UdP channel' do
        expect {described_class.new('UdP')}.not_to raise_error
      end
    end

    context 'support symbol' do
      it 'does not raise error for :udp channel' do
        expect {described_class.new(:udp)}.not_to raise_error
      end
    end
  end

  describe '#metric_for' do
    before :each do
      allow_any_instance_of(described_class).to receive(:set_backend)
      allow_any_instance_of(described_class).to receive(:setup_instrumentation)
      @instance = described_class.new(:udp)
    end

    context 'application state metric' do
      it 'return AppStateMetric class with string "app_state"' do
        expect(@instance.metric_for('app_state')).to be_eql D13n::Metric::AppStateMetric
      end

      it 'return AppStateMetric class with symbol :app_state' do
        expect(@instance.metric_for(:app_state)).to be_eql D13n::Metric::AppStateMetric
      end
    end

    context 'application HTTP metric' do
      it 'return AppHttpMetric class with app_http' do
        expect(@instance.metric_for(:app_http)).to be_eql D13n::Metric::AppHttpMetric
      end
    end

    context 'application database metric' do
      it 'return AppDatabaseMetric class with app_database' do
        expect(@instance.metric_for(:app_database)).to be_eql D13n::Metric::AppDatabaseMetric
      end
    end

    context 'biz state metric' do
      it 'return BizStateMetric class with biz_state' do
        expect(@instance.metric_for(:biz_state)).to be_eql D13n::Metric::BizStateMetric
      end
    end

    context 'wrong metric type' do
      it 'raise error' do
        expect { @instance.metric_for(:fake) }.to raise_error D13n::Metric::MetricNotFoundError
      end
    end
  end

  describe 'delegate' do
    before :each do
      allow_any_instance_of(described_class).to receive(:set_backend)
      allow_any_instance_of(described_class).to receive(:setup_instrumentation)
      @instance = described_class.new(:udp)
    end

    it 'responds to measure' do
      expect(@instance).to respond_to :measure
    end

    it 'responds to increment' do
      expect(@instance).to respond_to :increment
    end

    it 'responds to gauge' do
      expect(@instance).to respond_to :gauge
    end

    it 'responds to set' do
      expect(@instance).to respond_to :set
    end
  end
end