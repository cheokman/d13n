require 'spec_helper'
require 'd13n/rack/d13n_middleware'

describe D13n::Rack::D13nMiddleware do
  let(:dummy_app) {double()}
  describe '.initialize' do
    before :each do
      allow_any_instance_of(described_class).to receive(:build_stream_name).and_return("middleware.call")
      @instance = described_class.new(dummy_app)
    end

    it 'should have app' do
      expect(@instance.instance_variable_get(:@app)).to be_eql dummy_app
    end
    
    it 'should have middleware category' do
      expect(@instance.category).to be_eql :middleware
    end

    it 'should assign self as target' do
      expect(@instance.instance_variable_get(:@target)).to be_eql @instance
    end

    it 'should have stream options' do
      expect(@instance.stream_options).to be_eql({:stream_name => "middleware.call"})
    end
  end

  describe '#build_stream_name' do
    before :each do
      allow(::D13n::Metric::Instrumentation::ControllerInstrumentation::StreamNamer).to receive(:prefix_for_catory).and_return 'middleware'
    end
  end
end