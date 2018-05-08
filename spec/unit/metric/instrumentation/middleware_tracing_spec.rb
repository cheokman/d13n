require 'spec_helper'
require 'd13n/metric'
require 'd13n/metric/instrumentation/middleware_tracing'

describe D13n::Metric::Instrumentation::MiddlewareTracing do
  class DummyMiddleware
    include D13n::Metric::Instrumentation::MiddlewareTracing
  end
  let(:dm_instance) { DummyMiddleware.new }
  let(:dummy_stream) { double() }
  let(:dummy_state) { double() }
  before :each do
    allow_any_instance_of(DummyMiddleware).to receive(:category).and_return(:middleware)
    allow_any_instance_of(DummyMiddleware).to receive(:transaction_options).and_return({})
  end
  describe '#stream_started' do
    let(:started_key) {D13n::Metric::Instrumentation::MiddlewareTracing::STREAM_STARTED_KEY}
    context 'when not STREAM_STARTED_KEY' do
      before :each do
        @dummy_env = {}
        DummyMiddleware.new.stream_started(@dummy_env)
      end

      subject { @dummy_env[started_key] }
      it { is_expected.to be_truthy}
    end

    context 'when false STREAM_STARTED_KEY' do
      before :each do
        @dummy_env = {started_key => false}
        DummyMiddleware.new.stream_started(@dummy_env)
      end

      subject { @dummy_env[started_key] }
      it { is_expected.to be_truthy }
    end

    context 'when true STREAM_STARTED_KEY' do
      before :each do
        @dummy_env = {started_key => true}
        DummyMiddleware.new.stream_started(@dummy_env)
      end

      subject { @dummy_env[started_key] }
      it { is_expected.to be_truthy }

      it 'should return nil' do
        expect(DummyMiddleware.new.stream_started(@dummy_env)).to be_nil
      end
    end
  end

  describe '#call' do
   let(:dummy_env) { double() }
   let(:dummy_state) { double() }
   
    before :each do
      allow(D13n::Metric::StreamState).to receive(:st_get).and_return(dummy_state)
      allow(D13n::Metric::Stream).to receive(:start)
      allow(D13n::Metric::Stream).to receive(:stop)
      allow_any_instance_of(DummyMiddleware).to receive(:stream_started)
    end

    describe 'when exception accurred' do
      before :each do
        allow(D13n::Metric::Stream).to receive(:start).and_raise(ArgumentError)
      end

      it 'should call logger for error' do
        expect {dm_instance.call(dummy_env)}.to raise_error(ArgumentError)
      end

      it 'should call logger for error' do
        expect(D13n.logger).to receive(:error)
        begin
        dm_instance.call(dummy_env)
        rescue => e
        end
      end

      it 'should call logger for error' do
        expect(D13n::Metric::Stream).to receive(:stop)
        begin
        dm_instance.call(dummy_env)
        rescue => e
        end
      end
    end
  end

  describe '#capture_response_attribute' do
    
    let(:state) { double() }
    let(:result) { double() }
    before :each do
      allow(dm_instance).to receive(:capture_response_code)
      allow(dm_instance).to receive(:capture_response_content_type)
      allow(dm_instance).to receive(:capture_response_content_length)
    end

    it 'should call capture response code' do
      expect(dm_instance).to receive(:capture_response_code)
      dm_instance.capture_response_attribute(state, result)
    end

    it 'should call capture response content length' do
      expect(dm_instance).to receive(:capture_response_content_length)
      dm_instance.capture_response_attribute(state, result)
    end

    it 'should call capture response content type' do
      expect(dm_instance).to receive(:capture_response_content_type)
      dm_instance.capture_response_attribute(state, result)
    end
  end

  describe '#capture_response_code' do
    before :each do
      allow(dummy_stream).to receive(:http_response_code=)
    end

    context "when result is Array" do
      let(:dummy_result) { [200, 'headers', 'dummy'] }
      before(:each) do
        allow(dummy_state).to receive(:current_stream).and_return(dummy_stream)
      end

      it 'should assign http_response_code in current stream' do
        expect(dummy_stream).to receive(:http_response_code=).with(200)
        dm_instance.capture_response_code(dummy_state, dummy_result)
      end

      context 'when no current stream' do
        before :each do
          allow(dummy_state).to receive(:current_stream).and_return(nil)
        end

        it 'should not assign http_response_code in current stream' do
          expect(dummy_stream).not_to receive(:http_response_code=)
          dm_instance.capture_response_code(dummy_state, dummy_result)
        end
      end
    end

    context 'when result is no Array' do
      let(:dummy_result) { {} }
      before(:each) do
        allow(dummy_state).to receive(:current_stream).and_return(dummy_stream)
      end

      it 'should not assign http_response_code in current stream' do
        expect(dummy_stream).not_to receive(:http_response_code=)
        dm_instance.capture_response_code(dummy_state, dummy_result)
      end
    end
  end

  describe '#capture_response_content_type' do
    let(:dummy_headers) { {} } 
    let(:dummy_result) { [200, 'headers', 'dummy'] }
    before :each do
      allow(dummy_headers).to receive(:[]).with(D13n::Metric::Instrumentation::MiddlewareTracing::CONTENT_TYPE)
      allow(dummy_stream).to receive(:response_content_type=)
      allow(dummy_state).to receive(:current_stream).and_return(dummy_stream)
    end

    it 'should assign response_content_type' do
      expect(dummy_stream).to receive(:response_content_type=)
      dm_instance.capture_response_content_type(dummy_state, dummy_result)
    end
  end

  
end