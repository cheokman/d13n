require 'spec_helper'
require 'd13n/metric/conductor'

describe D13n::Metric::Instrumentation::Conductor::Performance do
  before :each do
    @instance = described_class.new 
  end

  describe '.new' do
    it 'has empty dependences list' do
      expect(@instance.dependences).to be_empty
    end

    it 'has emtpy Performances' do
      expect(@instance.instance_variable_get(:@performances)).to be_empty
    end

    it 'has nil name' do
      expect(@instance.name).to be_nil
    end

    it 'has nil performed' do
      expect(@instance.performed).to be_nil
    end
  end

  describe '#named' do
    it 'update name' do
      @instance.named 'new name'
      expect(@instance.name).to be_eql('new name')
    end
  end

  describe '#performances' do
    before :all do
      @proc1 = Proc.new { "say hi proc1" }
      @proc2 = Proc.new { "say hi proc2" }
    end

    it 'add new performance' do
      @instance.performances &@proc1
      expect(@instance.instance_variable_get(:@performances)).to be_eql [@proc1]
    end

    it 'append new performance' do
      @instance.performances &@proc1
      @instance.performances &@proc2
      expect(@instance.instance_variable_get(:@performances)).to be_eql [@proc1, @proc2]
    end
  end

  describe '#allowed_by_config?' do
    it 'return true if nil name' do
      expect(@instance.allowed_by_config?).to be_truthy
    end

    it 'return true if disable config missing' do
      @instance.named 'fake'
      expect(@instance.allowed_by_config?).to be_truthy
    end

    it 'return true if false disable config' do
      @instance.named 'fake'
      allow(D13n::Configuration::Manager).to receive(:[]).with(:'instrumentation.fake.disable').and_return(false)
      expect(@instance.allowed_by_config?).to be_truthy
    end

    it 'return false if true disable config' do
      @instance.named 'fake'
      allow(D13n::Configuration::Manager).to receive(:[]).with(:'instrumentation.fake.disable').and_return(true)
      expect(@instance.allowed_by_config?).to be_truthy
    end
  end

  describe '#depend_on' do
    before :all do
      @proc1 = Proc.new { "depend on proc1" }
      @proc2 = Proc.new { "depend on"}
    end

    it 'add new proc' do
      @instance.depend_on &@proc1
      expect(@instance.instance_variable_get(:@dependences)).to be_eql [@proc1]
    end

    it 'append new proc' do
      @instance.depend_on &@proc1
      @instance.depend_on &@proc2
      expect(@instance.instance_variable_get(:@dependences)).to be_eql [@proc1,@proc2]
    end
  end

  describe '#perform!' do
    before :each do
      @instance.perform!
    end

    it 'has set true in performed' do
      expect(@instance.performed).to be_truthy
    end
  end

  describe '#check_dependences' do
    context 'allowed_by_config? false' do
      before :each do
        allow(@instance).to receive(:allowed_by_config?).and_return(false)
      end

      it 'return false when no dependences' do
        @instance.instance_variable_set(:@dependences, [])
        expect(@instance.check_dependences).to be_falsey
      end

      it 'return false when not empty dependences' do
        @instance.instance_variable_set(:@dependences, ['hi'])
        expect(@instance.check_dependences).to be_falsey
      end
    end

    context 'allowed_by_config? true' do
      before :each do
        allow(@instance).to receive(:allowed_by_config?).and_return(true)
        @true_proc1 = Proc.new { true }
        @true_proc2 = Proc.new { true }
        @false_proc1 = Proc.new { false }
      end

      it 'return false when nil dependences' do
        @instance.instance_variable_set(:@dependences, nil)
        expect(@instance.check_dependences).to be_falsey
      end

      it 'return true when no any dependences' do
        @instance.instance_variable_set(:@dependences, [])
        expect(@instance.check_dependences).to be_truthy
      end

      it 'return true when all dependences are true' do
        @instance.depend_on &@true_proc1
        @instance.depend_on &@true_proc2
        expect(@instance.check_dependences).to be_truthy
      end

      it 'return false when any dependence is false' do
        @instance.depend_on &@true_proc1
        @instance.depend_on &@false_proc1
        @instance.depend_on &@true_proc2
        expect(@instance.check_dependences).to be_falsey
      end
    end
  end

  describe '#ready?' do
    context 'before perform' do
      it 'return true when no dependences' do
        expect(@instance.ready?).to be_truthy
      end

      it 'return true when true dependences' do
        allow(@instance).to receive(:check_dependences).and_return(true)
        expect(@instance.ready?).to be_truthy
      end

      it 'return false when fail dependences' do
        allow(@instance).to receive(:check_dependences).and_return(false)
        expect(@instance.ready?).to be_falsey
      end
    end

    context 'after perform' do
      before :each do
        @instance.perform!
      end

      it 'return false when no dependences' do
        expect(@instance.ready?).to be_falsey
      end

      it 'return false when true dependences' do
        allow(@instance).to receive(:check_dependences).and_return(true)
        expect(@instance.ready?).to be_falsey
      end

      it 'return false when fail dependences' do
        allow(@instance).to receive(:check_dependences).and_return(false)
        expect(@instance.ready?).to be_falsey
      end
    end
  end

  describe '#perfrom' do
    context 'when no performances' do
      it 'has updated to performed' do
        @instance.perform
        expect(@instance.performed).to be_truthy
      end

      it 'has no exception' do
        expect { @instance.perform }.not_to raise_error
      end
    end

    context 'when not empty performances' do
      before :each do
        @proc1 = Proc.new { "say hi performance1" }
        @proc2 = Proc.new { "say hi performance2" }
        @error_proc1 = Proc.new { raise "Oh Ooos" }
      end

      context 'no exception' do
        before :each do
          @instance.performances &@proc1
          @instance.performances &@proc2
        end

        it 'calls first' do
          expect(@proc1).to receive(:call)
          @instance.perform
        end

        it 'calls second' do
          expect(@proc2).to receive(:call)
          @instance.perform
        end

        it 'update to performed' do
          @instance.perform
          expect(@instance.performed).to be_truthy
        end
      end

      context 'raise exception' do
        before :each do
          @instance.performances &@proc1
          @instance.performances &@error_proc1
          @instance.performances &@proc2
        end

        it 'resuces exception' do
          expect { @instance.perform }.not_to raise_error
        end

        it 'is still performed' do
          @instance.perform
          expect(@instance.performed).to be_truthy
        end

        it 'called first' do
          expect(@proc1).to receive(:call)
          @instance.perform
        end

        it 'called first' do
          expect(@error_proc1).to receive(:call)
          @instance.perform
        end

        it 'did not call second' do
          expect(@proc2).not_to receive(:call)
          @instance.perform
        end
      end
    end
  end
end

describe D13n::Metric::Instrumentation::Conductor do
  before :each do
    described_class.clear
    @perf1 = Proc.new {
      named 'perf1'
      depend_on do
        true
      end
      performances do
        'say hi'
      end
    }
    @same_perf1 = Proc.new {
      named 'perf1'
      depend_on do
        true
      end
      performances do
        'say hi'
      end
    }
    @perf2 = Proc.new {
      named 'perf2'
      depend_on do
        true
      end
      performances do
        'say hi'
      end
    }
  end

  after :each do
    D13n::Metric::Instrumentation::Conductor.clear
  end

  describe '.direct' do
    before :each do
      described_class.direct &@perf1
      @concerts = described_class.instance_variable_get(:@concerts)
      @concert = @concerts[0]
    end

    it 'has named "perf1" concert' do
      expect(@concert.name).to be_eql('perf1')
    end

    it 'reject duplicated concert' do
      described_class.direct &@same_perf1
      @concerts = described_class.instance_variable_get(:@concerts)
      expect(@concerts.size).to be_eql(1)
    end
  end

  describe '.concert_by_name' do
    before :each do
      described_class.direct &@perf1
      described_class.direct &@perf2
    end

    it 'return perf2 concert' do
      expect(described_class.concert_by_name('perf2').name).to be_eql 'perf2'
    end
  end

  describe '.perfrom!' do
    before :each do
      @not_ready_perf3 = Proc.new {
        named 'perf3'
        depend_on do
          false
        end
        performances do
          'say hi'
        end
      }
      described_class.direct &@perf1
      described_class.direct &@not_ready_perf3
      described_class.direct &@perf2
    end

    it 'perform ready concert1' do
      described_class.perform!
      expect(described_class.concert_by_name('perf1').performed).to be_truthy
    end

    it 'perform ready concert2' do
      described_class.perform!
      expect(described_class.concert_by_name('perf2').performed).to be_truthy
    end

    it 'skip not ready concert3' do
      described_class.perform!
      expect(described_class.concert_by_name('perf3').performed).to be_falsey
    end
  end

  describe '.performed?' do
    before :each do
      @not_ready_perf3 = Proc.new {
        named 'perf3'
        depend_on do
          false
        end
        performances do
          'say hi'
        end
      }
      described_class.direct &@perf1
      described_class.direct &@not_ready_perf3
      described_class.direct &@perf2
    end

    context 'before perform' do
      it 'false for ready perfs' do
        expect(described_class.performed?('perf1')).to be_falsey
        expect(described_class.performed?('perf2')).to be_falsey
      end

      it 'false for not ready perfs' do
        expect(described_class.performed?('perf3')).to be_falsey
      end
    end

    context 'after perform' do
      it 'true fro ready perfs' do
        expect(described_class.performed?('perf1')).to be_falsey
        expect(described_class.performed?('perf2')).to be_falsey
      end

      it 'false for not ready perfs' do
        expect(described_class.performed?('perf3')).to be_falsey
      end
    end
  end

  describe '.clear' do
    before :each do
      described_class.direct &@perf1
      described_class.direct &@perf2
    end

    it 'clear all concerts' do
      described_class.clear
      expect(described_class.concerts).to be_empty
    end
  end

  describe '.concerts=' do
    before :each do
      described_class.direct &@perf1
      @performance = D13n::Metric::Instrumentation::Conductor::Performance.new.instance_eval(&@perf2)
    end

    it 'can assign new concerts list' do
      described_class.concerts = [@performance]
      expect(described_class.concerts).to be_eql [@performance]
    end
  end
end