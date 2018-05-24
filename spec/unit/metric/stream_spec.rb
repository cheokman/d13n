require 'spec_helper'
require 'd13n/metric'
require 'd13n/metric/stream'

describe D13n::Metric::Stream do
  let(:described_instance) { described_class.new("dummy_category", {:stream_name => 'dummy_sream'})}
  let(:dummy_frame) { double() }
  let(:dummy_frame_stack) {[dummy_frame]}
  let(:dummy_state) {double()}

  describe '#apdex_t' do
    before :each do
      allow(D13n.config).to receive(:[]).with(:apdex_t).and_return(100)
    end

    context 'when stream specific apdex_t not available' do
      before :each do
        allow(described_instance).to receive(:stream_specific_apdex_t).and_return nil
      end

      it 'should return global apdex_t' do
        expect(described_instance.apdex_t).to be_eql 100
      end
    end

    context 'when stream specific apdex_t available' do
      before :each do
        allow(described_instance).to receive(:stream_specific_apdex_t).and_return 200
      end

      it 'should return global apdex_t' do
        expect(described_instance.apdex_t).to be_eql 200
      end
    end
  end

  describe '#stream_specific_apdex_t' do
    before :each do
     
    end

    context 'when frozen_name available' do
      before :each do
        
        allow(D13n.config).to receive(:[]).with(:'web_stream_apdex_t.dummy_name').and_return(200)
        described_instance.instance_variable_set(:@frozen_name, 'dummy_name')
      end

      it 'should return config value by key' do
        expect(described_instance.stream_specific_apdex_t).to be_eql 200
      end
    end

    context 'when frozen_name not available' do
      it 'should return config value by key' do
        expect(described_instance.stream_specific_apdex_t).to be_nil
      end
    end
  end
  describe '#append_apdex_perf_zone' do
    
  end

  describe '#apdex_bucket' do
    it 'shoud call apdex_bucket class method' do
      expect(described_class).to receive(:apdex_bucket)
      described_instance.apdex_bucket(100, :apdex_s)
    end
  end

  describe 'had_error?' do
    context 'when empty exceptions' do
      before :each do
        described_instance.instance_variable_set(:@exceptions, {})
      end
      it 'should return false' do
        expect(described_instance.had_error?).to be_falsey
      end
    end

    context 'when exceptions' do
      before :each do
        described_instance.instance_variable_set(:@exceptions, {:error => 1})
      end
      it 'should return truth' do
        expect(described_instance.had_error?).to be_truthy
      end
    end
  end

  describe 'had_exception_affecting_apdex?' do
    before :each do
      allow(described_instance).to receive(:had_error?)
    end

    it 'should call had_error' do
      expect(described_instance).to receive(:had_error?)
      described_instance.had_exception_affecting_apdex?
    end
  end

  describe '#append_web_response' do
    let(:dummy_code) {200}
    let(:dummy_type) {'json'}
    let(:dummy_length) {321} 
    
    before :each do
      @metric_data = {}
    end

    context 'when nil response code' do
      it 'should return nil' do
        expect(described_instance.append_web_response(nil, dummy_type, dummy_length, @metric_data)).to be_nil
      end

      it 'should unchange metric_data' do
        old_data = @metric_data.dup
        described_instance.append_web_response(nil, dummy_type, dummy_length, @metric_data)
        expect(@metric_data).to be_eql old_data
      end
    end

    context 'when response code available' do
      it 'should return metric data with response information' do
        described_instance.append_web_response(dummy_code, dummy_type, dummy_length, @metric_data)
        expect(@metric_data).to be_eql ({
          :http_response_code => dummy_code,
          :http_response_content_type => dummy_type,
          :http_response_content_length => dummy_length
      })
      end
    end
  end

  describe '#make_stream_name' do
    before :each do
      allow(D13n::Metric::Instrumentation::ControllerInstrumentation::StreamNamer).to receive(:prefix_for_category).and_return('dummy_category')
    end

    it 'should return #{category}.#{name} stream name' do
      expect(described_instance.make_stream_name("service.get_player")).to be_eql "dummy_category.service.get_player"
    end
  end

  describe '#name_last_frame' do
    
    before :each do
      allow(dummy_frame).to receive(:name=)
      described_instance.instance_variable_set(:@frame_stack, dummy_frame_stack)
    end

    it 'should update name of last frame' do
      expect(dummy_frame).to receive(:name=).with('dummy')
      described_instance.name_last_frame('dummy')
    end
  end

  describe '#notice_error' do
    let(:dummy_error) { RuntimeError }
    context 'when new error' do
      before :each do
        described_instance.notice_error(dummy_error, {:a => 1})
      end
      it 'should add error to exceptions list as key' do
        exceptions = described_instance.instance_variable_get(:@exceptions)
        expect(exceptions).to include (dummy_error)
      end

      it 'should add options to exceptions list as value' do
        exceptions = described_instance.instance_variable_get(:@exceptions)
        expect(exceptions[dummy_error]).to be_eql({:a => 1})
      end
    end

    context 'when error exist' do
      before :each do
        described_instance.instance_variable_set(:@exceptions, {dummy_error => {:b => 2}})
      
      end

      context 'when different options' do
        before :each do
          described_instance.notice_error(dummy_error, {:a => 1})
        end

        it "should merge options to existing error" do
          exceptions = described_instance.instance_variable_get(:@exceptions)
          expect(exceptions[dummy_error]).to be_eql({:a => 1, :b => 2})
        end
      end

      context 'when same options' do
        before :each do
          described_instance.notice_error(dummy_error, {:b => 2})
        end

        it "should merge options to existing error" do
          exceptions = described_instance.instance_variable_get(:@exceptions)
          expect(exceptions[dummy_error]).to be_eql({:b => 2})
        end
      end
    end
  end

  describe '#create_nested_stream' do
    before :each do
      allow(D13n::Metric::Stream::SpanTracerHelpers).to receive(:trace_header).and_return(dummy_frame)
      allow(described_instance).to receive(:name_last_frame)
      allow(described_instance).to receive(:set_default_stream_name)
      described_instance.instance_variable_set(:@frame_stack, dummy_frame_stack)
    end

    it 'should set has_children true' do
      described_instance.create_nested_stream(dummy_state, 'dummy_category',{})
      expect(described_instance.instance_variable_get(:@has_children)).to be_truthy
    end

    it 'should push frame to stack' do
      expect(dummy_frame_stack).to receive(:push)
      described_instance.create_nested_stream(dummy_state, 'dummy_category',{})
    end

    it 'should set name of last frame' do
      expect(described_instance).to receive(:name_last_frame)
      described_instance.create_nested_stream(dummy_state, 'dummy_category',{})
    end
    it 'should set name of last frame' do
      expect(described_instance).to receive(:set_default_stream_name)
      described_instance.create_nested_stream(dummy_state, 'dummy_category',{})
    end
  end

  describe '#set_default_stream_name' do
    context 'when category nil' do
      before :each do
        described_instance.set_default_stream_name('dummy', nil)
      end

      it 'should have dummy default name' do
        expect(described_instance.instance_variable_get(:@default_name)).to be_eql("dummy")
      end

      it 'should have unchanged category' do
        expect(described_instance.instance_variable_get(:@category)).to be_eql("dummy_category")
      end
    end

    context 'when category not nil' do
      before :each do
        described_instance.set_default_stream_name('dummy', 'updated_category')
      end

      it 'should have dummy default name' do
        expect(described_instance.instance_variable_get(:@default_name)).to be_eql("dummy")
      end

      it 'should have updated_category category' do
        expect(described_instance.instance_variable_get(:@category)).to be_eql("updated_category")
      end
    end
  end

  describe '#name_frozen?' do
    context 'when nil frozen name' do
      before :each do
        described_instance.instance_variable_set(:@frozen_name, nil)
      end

      it 'should be falsy' do
        expect(described_instance.name_frozen?).to be_falsy
      end
    end

    context 'when frozen name vailable' do
      before :each do
        described_instance.instance_variable_set(:@frozen_name, 'aaa')
      end

      it 'should be falsy' do
        expect(described_instance.name_frozen?).to be_truthy
      end
    end
  end

  describe '#recording_web_transaction?' do
    context 'when in category' do
      described_class::WEB_TRANSACTION_CATEGORIES.each do |c|
        it 'should return true' do
          described_instance.instance_variable_set(:@category, c)
          expect(described_instance.recording_web_transaction?).to be_truthy
        end
      end
    end

    context 'when not in category' do
      it 'should return false' do
        described_instance.instance_variable_set(:@category, :event_machine)
        expect(described_instance.recording_web_transaction?).to be_falsy
      end
    end
  end


  describe '#web_category?' do
    context 'when in category' do
      described_class::WEB_TRANSACTION_CATEGORIES.each do |c|
        it 'should return true' do
          expect(described_instance.web_category?(c)).to be_truthy
        end
      end
    end

    context 'when not in category' do
      it 'should return false' do
        expect(described_instance.web_category?(:event_machine)).to be_falsy
      end
    end
  end

  describe '#uuid' do
    let(:dummy_request_info) {{'request_id' => 'aaa'}}
    before :each do
      allow(D13n::Metric::StreamState).to receive(:request_info).and_return dummy_request_info
    end

    context 'when uuid available' do
      before :each do
        described_instance.instance_variable_set(:@uuid, 'bbb')
      end

      it 'should return uuid' do
        expect(described_instance.uuid).to be_eql 'bbb'
      end
    end 

    context 'when nil uuid' do
      context 'when nil request id' do
        before :each do
          allow(D13n::Metric::StreamState).to receive(:request_info).and_return({})
          allow(SecureRandom).to receive(:hex).and_return('ccc')
        end

        it 'should genearte new uuid' do
          expect(described_instance.uuid).to be_eql 'ccc'
        end
      end

      context 'when request id avaliable' do
        it 'should assign request id as uuid' do
          expect(described_instance.uuid).to be_eql 'aaa'
        end
      end
    end


  end

  describe '#get_id' do
    before :each do
      allow(described_instance).to receive(:uuid).and_return 'ccc'
    end

    it 'should return uuid' do
      expect(described_instance.get_id).to be_eql 'ccc'
    end
  end

  describe '.apdex_bucket' do
    let(:dummy_apdex_t) {100}
    let(:dummy_duration_s) {40}
    let(:dummy_duration_t) {300}
    let(:dummy_duration_f) {500}

    context 'when failed' do
      it 'should be drop in apdex_f bucket' do
        expect(described_class.apdex_bucket(dummy_duration_s, true, dummy_apdex_t)).to be_eql :apdex_f
      end
    end

    context 'when not failed' do
      context 'when satified' do
        it 'should be drop in apdex_s bucket' do
          expect(described_class.apdex_bucket(dummy_duration_s, false, dummy_apdex_t)).to be_eql :apdex_s
        end
      end

      context 'when tolerating' do
        it 'should be drop in apdex_t bucket' do
          expect(described_class.apdex_bucket(dummy_duration_t, false, dummy_apdex_t)).to be_eql :apdex_t
        end
      end

      context 'when frustrated' do
        it 'should be drop in apdex_f bucket' do
          expect(described_class.apdex_bucket(dummy_duration_f, false, dummy_apdex_t)).to be_eql :apdex_f
        end
      end
    end
  end

  describe '.set_default_stream_name' do
    before :each do
      allow(described_class).to receive(:st_current).and_return(described_instance)
      allow(described_instance).to receive(:name_last_frame)
      allow(described_instance).to receive(:make_stream_name)
      allow(described_instance).to receive(:set_default_stream_name)
    end

    it 'should call name_last_frame' do
      expect(described_instance).to receive(:name_last_frame)
      described_class.set_default_stream_name('service.get_player')
    end

    it 'should call make_stream_name' do
      expect(described_instance).to receive(:make_stream_name)
      described_class.set_default_stream_name('service.get_player')
    end

    it 'should call set_default_stream_name' do
      expect(described_instance).to receive(:set_default_stream_name)
      described_class.set_default_stream_name('service.get_player')
    end
  end
end