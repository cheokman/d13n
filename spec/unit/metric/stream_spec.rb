require 'spec_helper'
require 'd13n/metric'
require 'd13n/metric/stream'

describe D13n::Metric::Stream do
  let(:described_instance) { described_class.new("dummy_category", {:stream_name => 'dummy_sream'})}
  let(:dummy_frame) { double() }
  let(:dummy_frame_stack) {[dummy_frame]}
  let(:dummy_state) {double()}
  let(:dummy_stream) {double()}

  describe '#start' do
    before :each do
      allow(D13n::Metric::Stream::SpanTracerHelpers).to receive(:trace_header).and_return dummy_frame
      allow(dummy_frame).to receive(:name=)
      described_instance.instance_variable_set(:@frame_stack, dummy_frame_stack)
    end

    it 'should push a new frame' do
      expect(dummy_frame_stack).to receive(:push)
      described_instance.start(dummy_state)
    end

    it 'should set last frame name' do
      expect(dummy_frame).to receive(:name=)
      described_instance.start(dummy_state)
    end
  end

  describe '#stop' do
    before :each do
      allow(described_class).to receive(:nested_stream_name)
      allow(described_instance).to receive(:commit!)
      allow(dummy_frame).to receive(:children_time).and_return(0)
    end

    it 'should call span tracer trace_footer' do
      expect(D13n::Metric::Stream::SpanTracerHelpers).to receive(:trace_footer)
      described_instance.stop(dummy_state, 1000, dummy_frame)
    end

    context 'when ignore_this_stream' do
      before :each do
        described_instance.instance_variable_set(:@ignore_this_stream, true)
        allow(D13n::Metric::Stream::SpanTracerHelpers).to receive(:trace_footer)
      end

      it 'should not call commit!' do
        expect(described_instance).not_to receive(:commit!)
        described_instance.stop(dummy_state, 1000, dummy_frame)
      end
    end

    context 'when not ignore_this_stream' do
      before :each do
        described_instance.instance_variable_set(:@ignore_this_stream, false)
        allow(D13n::Metric::Stream::SpanTracerHelpers).to receive(:trace_footer)
      end

      it 'should not call commit!' do
        expect(described_instance).to receive(:commit!)
        described_instance.stop(dummy_state, 1000, dummy_frame)
      end
    end

    context 'when has children' do
      before :each do
        allow(D13n::Metric::Stream::SpanTracerHelpers).to receive(:trace_footer)
        allow(described_instance).to receive(:commit!)
        allow(dummy_frame).to receive(:name)
        described_instance.instance_variable_set(:@has_children, true)
      end

      it 'should call nested_stream_name' do
        allow(described_class).to receive(:nested_stream_name)
        described_instance.stop(dummy_state, 1000, dummy_frame)
      end

    end
  end

  describe '#commit!' do
    before :each do
      allow(described_instance).to receive(:collect_metric_data)
      allow(described_instance).to receive(:collect_metrics)
    end

    it 'should call collect_metric_data' do
      expect(described_instance).to receive(:collect_metric_data)
      described_instance.commit!(dummy_state, 100, 1000)
    end

    it 'should call collect_metrics' do
      expect(described_instance).to receive(:collect_metrics)
      described_instance.commit!(dummy_state, 100, 1000)
    end
  end

  describe '#collect_metrics' do
    before :each do
      allow(D13n::Metric::Stream::StreamTracerHelpers).to receive(:collect_metrics)
    end

    it 'should call stream tracer' do
      expect(D13n::Metric::Stream::StreamTracerHelpers).to receive(:collect_metrics)
      described_instance.collect_metrics(dummy_state, {})
    end
  end

  describe '#collect_metric_data' do
    before :each do
      allow(described_instance).to receive(:generate_metric_data)
    end

    it 'should call generate_metric_data' do
      expect(described_instance).to receive(:generate_metric_data)
      described_instance.collect_metric_data(dummy_state, {})
    end
  end

  describe 
  describe '#generate_error_data' do
    before :each do
      @dummy_metric_data = {}
    end 

    context 'when no error' do
      before :each do
        allow(described_instance).to receive(:had_error?).and_return(false)
      end
      it 'should unchange metric_data' do
        old_metric_data = @dummy_metric_data.dup
        described_instance.generate_error_data(@dummy_metric_data)
        expect(@dummy_metric_data).to be_eql old_metric_data
      end
    end

    context 'when error' do
      before :each do
        allow(described_instance).to receive(:had_error?).and_return(true)
        described_instance.instance_variable_set(:@exceptions, {:error => 1})
      end
      it 'should unchange metric_data' do
        described_instance.generate_error_data(@dummy_metric_data)
        expect(@dummy_metric_data).to be_eql({
          :error => true,
          :errors => {:error => 1}
        })
      end
    end
  end
  
  describe '#default_metric_data' do
    let(:dummy_frozen_name) {'frozen_name'}
    let(:dummy_default_name) {'default_name'}
    let(:dummy_error_data) {{:error => 1}}

    before :each do
      allow(described_instance).to receive(:generate_error_data)
      allow(dummy_state).to receive(:referring_stream_id).and_return('aaa')
      described_instance.instance_variable_set(:@default_name, dummy_default_name)
      described_instance.instance_variable_set(:@uuid, 'ccc')
    end

    context 'when no referring_stream_id' do
      before :each do
        allow(dummy_state).to receive(:referring_stream_id).and_return(nil)
        described_instance.instance_variable_set(:@state, dummy_state)
      end
      it 'should have default keys' do
        expect(described_instance.default_metric_data).to include(:name, :uuid, :error)
      end

      it 'should have default name' do
        expect(described_instance.default_metric_data[:name]).to be_eql(dummy_default_name)
      end

      it 'should have uuid' do
        expect(described_instance.default_metric_data[:uuid]).to be_eql('ccc')
      end

      context 'when no error' do
        it 'should have error false' do
          expect(described_instance.default_metric_data[:error]).to be_falsey
        end
      end
    end

    context 'when referring_stream_id' do
      before :each do
        described_instance.instance_variable_set(:@state, dummy_state)
      end

      it 'should have referring_stream_id key' do
        expect(described_instance.default_metric_data).to include(:name, :uuid, :error,:referring_stream_id)
      end

      it 'should have referring_stream_id value' do
        expect(described_instance.default_metric_data[:referring_stream_id]).to be_eql('aaa') 
      end
    end
  end

  describe '#generate_default_metric_data' do
    let(:dummy_default_metric_data) {{:default => true} }
    
    before :each do
      allow(described_instance).to receive(:default_metric_data).and_return(dummy_default_metric_data)
    end

    it 'should have default keys' do
      expect(described_instance.generate_default_metric_data(dummy_state, 100,200, {})).to include(:default, :type, :started_at, :duration)
    end

    it 'should have default type value' do
      metric_data = {}
      described_instance.generate_default_metric_data(dummy_state, 100, 200, metric_data)
      expect(metric_data[:type]).to be_eql(:request)
    end

    it 'should have started_at value' do
      metric_data = {}
      described_instance.generate_default_metric_data(dummy_state, 100, 200, metric_data)
      expect(metric_data[:started_at]).to be_eql(100)
    end

    it 'should have duration value' do
      metric_data = {}
      described_instance.generate_default_metric_data(dummy_state, 100, 200, metric_data)
      expect(metric_data[:duration]).to be_eql(100)
    end
  end

  describe '#generate_metric_data' do
    before :each do
      allow(described_instance).to receive(:generate_default_metric_data)
      allow(described_instance).to receive(:append_apdex_perf_zone)
      allow(described_instance).to receive(:append_web_response)
    end

    it 'should call generate_default_metric_data' do
      expect(described_instance).to receive(:generate_default_metric_data)
      described_instance.generate_metric_data(dummy_state, {}, 1000, 2000)
    end

    it 'should call append_apdex_perf_zone' do
      expect(described_instance).to receive(:append_apdex_perf_zone)
      described_instance.generate_metric_data(dummy_state, {}, 1000, 2000)
    end

    context 'when web transaction' do
      before :each do
        allow(described_instance).to receive(:recording_web_transaction?).and_return(true)
      end
      it 'should call append_web_response' do
        expect(described_instance).to receive(:append_web_response)
        described_instance.generate_metric_data(dummy_state, {}, 1000, 2000)
      end
    end

    context 'when not web transaction' do
      before :each do
        allow(described_instance).to receive(:recording_web_transaction?).and_return(false)
      end
      it 'should call append_web_response' do
        expect(described_instance).not_to receive(:append_web_response)
        described_instance.generate_metric_data(dummy_state, {}, 1000, 2000)
      end
    end

  end

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
    before :each do
      @dummy_metric_data = {}

    end

    context 'when bucket nil or false' do
      before :each do
        allow(described_instance).to receive(:apdex_bucket).and_return(nil)
      end

      it 'should return nil' do
        expect(described_instance.append_apdex_perf_zone(100, @dummy_metric_data)).to be_nil
      end

      it 'should unchange metric_data' do
        old_metric_data = @dummy_metric_data.dup
        described_instance.append_apdex_perf_zone(100, @dummy_metric_data)
        expect(@dummy_metric_data).to be_eql old_metric_data
      end
    end

    context 'when bucket return :apdex_s' do
      before :each do
        allow(described_instance).to receive(:apdex_bucket).and_return(:apdex_s)
      end

      it 'should update metric_data with APDEX_S' do
        described_instance.append_apdex_perf_zone(100, @dummy_metric_data)
        expect(@dummy_metric_data[:apdex_perf_zone]).to be_eql described_class::APDEX_S
      end
    end

    context 'when bucket return :apdex_t' do
      before :each do
        allow(described_instance).to receive(:apdex_bucket).and_return(:apdex_t)
      end

      it 'should update metric_data with APDEX_T' do
        described_instance.append_apdex_perf_zone(100, @dummy_metric_data)
        expect(@dummy_metric_data[:apdex_perf_zone]).to be_eql described_class::APDEX_T
      end
    end

    context 'when bucket return :apdex_f' do
      before :each do
        allow(described_instance).to receive(:apdex_bucket).and_return(:apdex_f)
      end

      it 'should update metric_data with APDEX_F' do
        described_instance.append_apdex_perf_zone(100, @dummy_metric_data)
        expect(@dummy_metric_data[:apdex_perf_zone]).to be_eql described_class::APDEX_F
      end
    end

    context 'when bucket other than above' do
      before :each do
        allow(described_instance).to receive(:apdex_bucket).and_return(:apdex)
      end

      it 'should unchange metric_data' do
        old_metric_data = @dummy_metric_data.dup
        described_instance.append_apdex_perf_zone(100, @dummy_metric_data)
        expect(@dummy_metric_data).to be_eql old_metric_data
      end
    end
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

  describe '.st_current' do
    before :each do
      allow(D13n::Metric::StreamState).to receive(:st_get).and_return(dummy_state)
      allow(dummy_state).to receive(:current_stream).and_return(described_instance)
    end

    it 'should return current stream' do
      expect(described_class.st_current).to be_eql described_instance
    end
  end

  describe '.start' do
    context 'when exception' do
      before :each do
        allow(dummy_state).to receive(:current_stream).and_raise("error")
      end

      it 'should log in error' do
        expect(D13n.logger).to receive(:error)
        described_class.start(dummy_state, nil, {})
      end

      it 'should return nil' do
        expect(described_class.start(dummy_state, nil, {})).to be_nil
      end

      it 'should return nil' do
        expect {described_class.start(dummy_state, nil, {})}.not_to raise_error
      end
    end

    context 'when stream available' do
      before :each do
        allow(dummy_state).to receive(:current_stream).and_return described_instance
      end

      it 'should call stream create_nested_stream' do
        expect(described_instance).to receive(:create_nested_stream)
        described_class.start(dummy_state, nil, {})
      end
    end

    context 'when stream not available' do
      before :each do
        allow(dummy_state).to receive(:current_stream).and_return nil
      end

      it 'should call start_new_stream' do
        expect(described_class).to receive(:start_new_stream)
        described_class.start(dummy_state, nil, {})
      end
    end


  end

  describe '.start_new_stream' do
    let(:new_state) {D13n::Metric::StreamState.new}
    it 'should call state reset' do
      expect(new_state).to receive(:reset)
      described_class.start_new_stream(new_state, :controller, {})
    end

    it 'should save state in stream' do
      stream = described_class.start_new_stream(new_state, :controller, {})
      expect(stream.state).to be_eql(new_state)
    end
  end

  describe '.stop' do
    context 'when stream not avaliable' do
      before :each do
        allow(dummy_state).to receive(:current_stream).and_return nil
      end

      it 'should return nil' do
        expect(described_class.stop(dummy_state)).to be_nil
      end

      it 'should call log error' do
        expect(D13n.logger).to receive(:error)
        described_class.stop(dummy_state)
      end
    end

    context 'when stream avaliable' do
      before :each do
        allow(dummy_state).to receive(:current_stream).and_return described_instance
        allow(described_instance).to receive(:frame_stack).and_return dummy_frame_stack
        allow(dummy_state).to receive(:reset)
        allow(described_instance).to receive(:stop)
      end

      context 'when frame stack empty' do
        before :each do
          allow(dummy_frame_stack).to receive(:empty?).and_return(true)
        end

        it 'should stop stream' do
          expect(described_instance).to receive(:stop)
          described_class.stop(dummy_state)
        end

        it 'should reset stream state' do
          expect(dummy_state).to receive(:reset)
          described_class.stop(dummy_state)
        end
      end

      context 'when frame stack not empty' do
        before :each do
          allow(dummy_frame_stack).to receive(:empty?).and_return(false)
          allow(described_class).to receive(:nested_stream_name)
          allow(D13n::Metric::Stream::SpanTracerHelpers).to receive(:trace_footer)
          allow(dummy_frame).to receive(:name)
          allow(dummy_frame).to receive(:start_time).and_return(100)
        end

        it 'should call nested_stream_name' do
          expect(described_class).to receive(:nested_stream_name)
          described_class.stop(dummy_state)
        end

        it 'should call trace_footer' do
          expect(D13n::Metric::Stream::SpanTracerHelpers).to receive(:trace_footer)
          described_class.stop(dummy_state)
        end

      end
    end
  end

  describe '.notice_error' do
    let(:dummy_error_opt) {{:error => 1}}
    before :each do
      allow(D13n::Metric::StreamState).to receive(:st_get).and_return(dummy_state)
    
    end

    context 'when stream available' do
      before :each do
        allow(dummy_state).to receive(:current_stream).and_return described_instance
      end

      it 'should call stream instance notice_error' do
        expect(described_instance).to receive(:notice_error)
        described_class.notice_error(RuntimeError, dummy_error_opt)
      end
    end

    context 'when stream not available' do
      before :each do
        allow(dummy_state).to receive(:current_stream).and_return nil
      end

      it 'should call stream instance notice_error' do
        expect(described_instance).not_to receive(:notice_error)
        described_class.notice_error(RuntimeError, dummy_error_opt)
      end
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