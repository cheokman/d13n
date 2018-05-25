require 'spec_helper'
require 'd13n/metric'
require 'd13n/metric/stream_state'

describe D13n::Metric::StreamState do
  let(:dummy_store) {{}}
  let(:described_instance) { described_class.new }
  let(:dummy_request_info) {{:request => 'a'}}
  let(:dummy_stream) { double() }
  let(:dummy_request) { {D13n::Metric::StreamState::D13N_STREAM_HEADER => 'aaa'}}
  describe '.st_state_for' do
    before :each do
      described_class.st_state_for(dummy_store)
    end
    it 'should store instance by key d13n_stream_state' do
      expect(dummy_store).to include :d13n_stream_state    
    end

    it 'should store new instance' do
      expect(dummy_store[:d13n_stream_state]).to be_kind_of described_class
    end

    it 'should return same instance with multiple retrive' do
      first = described_class.st_state_for(dummy_store)
      second = described_class.st_state_for(dummy_store)
      expect(first).to be_eql second
    end
  end

  describe '.st_get' do
    it 'should return a instance in first call' do
      expect(described_class.st_get).to be_kind_of described_class
    end

    it 'should return same instance in multiple retrieve' do
      first = described_class.st_get
      second = described_class.st_get
      expect(first).to be_eql second
    end
  end

  describe '.request_info' do
    before :each do
      described_instance.request_info = dummy_request_info
      allow(described_class).to receive(:st_get).and_return described_instance
    end

    it 'should return request info from instance' do
      expect(described_class.request_info).to be_eql dummy_request_info
    end
  end

  describe '.default_metric_data' do
    before :each do
      allow(described_class).to receive(:st_get).and_return described_instance
      
    end

    context 'when current stream exist' do
      before :each do
        allow(described_instance).to receive(:current_stream).and_return dummy_stream
      end

      it 'should call stream default_metric_data' do
        expect(dummy_stream).to receive(:default_metric_data)
        described_class.default_metric_data
      end
    end

    context 'when current stream not exist' do
      before :each do
        allow(described_instance).to receive(:current_stream).and_return nil
      end

      it 'should return empty hash' do
        expect(described_class.default_metric_data).to be_kind_of Hash
        expect(described_class.default_metric_data).to be_empty
      end
    end
  end

  describe '#reset' do
    before :each do
      
    end
    it 'should clean span stack' do
      expect(described_instance.traced_span_stack).to receive(:clear)
      described_instance.reset(dummy_stream)
    end

    it 'should set current stream as new stream' do
      described_instance.reset(dummy_stream)
      expect(described_instance.current_stream).to be_eql dummy_stream
    end

    it 'should set is_cross_app_caller to false' do
      described_instance.reset(dummy_stream)
      expect(described_instance.is_cross_app_caller).to be_falsey
    end
  end

  describe '#notify_rack_call' do
    it 'should call notify_call' do
      expect(described_instance).to receive(:notify_call)
      described_instance.notify_rack_call(dummy_request)
    end
  end

  describe '#notify_call' do
   it 'should save referring stream id' do
     expect(described_instance).to receive(:save_referring_stream_id)
     described_instance.notify_call(dummy_request)
   end
  end

  describe '#save_referring_stream_id' do
    context 'when header exist' do
      it 'should save referring stream id in header' do
        described_instance.save_referring_stream_id(dummy_request)
        expect(described_instance.referring_stream_id).to be_eql dummy_request[D13n::Metric::StreamState::D13N_STREAM_HEADER]
      end
    end
  end

  describe '#clear_referring_stream_id' do
    it 'should clear id' do
      described_instance.clear_referring_stream_id
      expect(described_instance.referring_stream_id).to be_nil
    end
  end
end