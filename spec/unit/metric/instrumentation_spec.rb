require 'spec_helper'
require 'd13n/metric'

describe D13n::Metric::Instrumentation do
  before :each do
    @kls = Class.new { include D13n::Metric::Instrumentation}
    @instance = @kls.new
  end
  
  describe '._setup_instrumentation' do
    before :each do
      allow(D13n::Metric::Instrumentation::Conductor).to receive(:perform!)
    end
    context 'when instrumented' do
      it 'return nil' do
        @instance.instance_variable_set(:@instrumentd, true)
        expect(@instance.send :_setup_instrumentation).to be_nil
      end
    end

    context 'when not instrumented' do
      it 'load all instrumentation files' do
        expect(@instance).to receive(:load_instrumentation_files)
        @instance.send :_setup_instrumentation
      end

      it 'perform all instrumentation' do
        expect(D13n::Metric::Instrumentation::Conductor).to receive(:perform!)
        @instance.send :_setup_instrumentation
      end
    end
  end
end