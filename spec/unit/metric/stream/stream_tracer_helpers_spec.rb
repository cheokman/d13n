require 'spec_helper'
require 'd13n/metric'
require 'd13n/metric/stream/stream_tracer_helpers'
describe D13n::Metric::Stream::StreamTracerHelpers do
  let(:dummy_collector) {double()}
  let(:dummy_state) {double()}
  let(:dummy_timing) {1.0}
  let(:dummy_gauge) {10}
  let(:dummy_metric_data) {double()}
  let(:dummy_error) {double()}
  let(:dummy_errors) {[ArgumentError.new, RuntimeError]}
  before :each do
    allow(dummy_collector).to receive(:increment)
    allow(dummy_collector).to receive(:gauge)
    allow(dummy_collector).to receive(:measure)
    allow(described_class).to receive(:metric_name).with("timing").and_return('timing')
    allow(described_class).to receive(:metric_name).with("count").and_return('count')
    allow(described_class).to receive(:metric_name).with("gauge").and_return('gauge')
    allow(described_class).to receive(:stream_duration_tags).and_return("tags")
    allow(described_class).to receive(:stream_exclusive_tags).and_return("tags")
    allow(described_class).to receive(:stream_apdex_tags).and_return("tags")
    allow(described_class).to receive(:stream_error_tags).and_return("tags")
    allow(described_class).to receive(:stream_http_response_code_tags).and_return("tags")
    allow(described_class).to receive(:stream_http_response_content_type_tags).and_return("tags")
    allow(described_class).to receive(:stream_http_response_content_length_tags).and_return("tags")
  end

  describe 'collect_duration_metric' do
    it 'should call collector measure' do
      expect(dummy_collector).to receive(:measure)
      described_class.collect_duration_metric(dummy_collector, dummy_state, dummy_timing, dummy_metric_data)
    end
  end

  describe 'collect_exclusive_metric' do
    it 'should call collector measure' do
      expect(dummy_collector).to receive(:measure)
      described_class.collect_exclusive_metric(dummy_collector, dummy_state, dummy_timing, dummy_metric_data)
    end
  end

  describe 'collect_apdex_metric' do
    it 'should call collector increment' do
      expect(dummy_collector).to receive(:increment)
      described_class.collect_apdex_metric(dummy_collector, dummy_state, dummy_metric_data)
    end
  end

  describe 'collect_repsonse_code_metric' do
    it 'should call collector increment' do
      expect(dummy_collector).to receive(:increment)
      described_class.collect_repsonse_code_metric(dummy_collector, dummy_state, dummy_metric_data)
    end
  end

  describe 'collect_response_content_type_metric' do
    it 'should call collector increment' do
      expect(dummy_collector).to receive(:increment)
      described_class.collect_response_content_type_metric(dummy_collector, dummy_state, dummy_metric_data)
    end
  end

  describe 'collect_response_content_length_metric' do
    it 'should call collector increment' do
      expect(dummy_collector).to receive(:gauge)
      described_class.collect_response_content_length_metric(dummy_collector, dummy_state, dummy_gauge, dummy_metric_data)
    end
  end

  describe 'collect_response_metric' do
    before :each do
      allow(dummy_metric_data).to receive(:[]).with(:http_response_content_length)
    end
    it 'should call collect_repsonse_code_metric' do
      expect(described_class).to receive(:collect_repsonse_code_metric)
      described_class.collect_response_metric(dummy_collector, dummy_state, dummy_metric_data)
    end
    it 'should call collect_response_content_type_metric' do
      expect(described_class).to receive(:collect_response_content_type_metric)
      described_class.collect_response_metric(dummy_collector, dummy_state, dummy_metric_data)
    end
    it 'should call collect_response_content_length_metric' do
      expect(described_class).to receive(:collect_response_content_length_metric)
      described_class.collect_response_metric(dummy_collector, dummy_state, dummy_metric_data)
    end
  end

  describe '#collect_error_metric' do
    it 'should call collector increment' do
      expect(dummy_collector).to receive(:increment)
      described_class.collect_error_metric(dummy_collector, dummy_state, dummy_error, dummy_metric_data)
    end
  end

  describe '#collect_errors_metric' do
    before :each do
      allow(dummy_metric_data).to receive(:[]).and_return(dummy_errors)
    end
    it 'should call error metric one by one' do
      expect(described_class).to receive(:collect_error_metric).exactly(dummy_errors.size).times
      described_class.collect_errors_metric(dummy_collector, dummy_state, dummy_metric_data)
    end
  end

  describe '#collect_metrics' do
    before :each do
      allow(D13n::Metric::Manager).to receive(:instance).and_return(dummy_collector)
      allow(dummy_metric_data).to receive(:[]).with(:duration).and_return(dummy_timing)
      allow(dummy_metric_data).to receive(:[]).with(:exclusive).and_return(dummy_timing)
      allow(dummy_metric_data).to receive(:[]).with(:http_response_content_length).and_return(300)
    end

    context "when no error" do
      before :each do
        allow(dummy_metric_data).to receive(:[]).with(:error).and_return(false)
      end
      it 'should call duration metric collection' do
        expect(described_class).to receive(:collect_duration_metric)
        described_class.collect_metrics(dummy_state, dummy_metric_data)
      end
      it 'should call exclusive metric collection' do
        expect(described_class).to receive(:collect_exclusive_metric)
        described_class.collect_metrics(dummy_state, dummy_metric_data)
      end
      it 'should call apdex metric collection' do
        expect(described_class).to receive(:collect_apdex_metric)
        described_class.collect_metrics(dummy_state, dummy_metric_data)
      end
      it 'should call response metric collection' do
        expect(described_class).to receive(:collect_response_metric)
        described_class.collect_metrics(dummy_state, dummy_metric_data)
      end

      it 'shoule not call errors metric' do
        expect(described_class).not_to receive(:collect_errors_metric)
        described_class.collect_metrics(dummy_state, dummy_metric_data)
      end
    end


    context "when error" do
      before :each do
        allow(dummy_metric_data).to receive(:[]).with(:error).and_return(true)
        allow(dummy_metric_data).to receive(:[]).with(:errors).and_return(dummy_errors)
      end
      it 'should call duration metric collection' do
        expect(described_class).to receive(:collect_duration_metric)
        described_class.collect_metrics(dummy_state, dummy_metric_data)
      end
      it 'should call exclusive metric collection' do
        expect(described_class).to receive(:collect_exclusive_metric)
        described_class.collect_metrics(dummy_state, dummy_metric_data)
      end
      it 'should call apdex metric collection' do
        expect(described_class).to receive(:collect_apdex_metric)
        described_class.collect_metrics(dummy_state, dummy_metric_data)
      end
      it 'should call response metric collection' do
        expect(described_class).to receive(:collect_response_metric)
        described_class.collect_metrics(dummy_state, dummy_metric_data)
      end

      it 'shoule call errors metric' do
        expect(described_class).to receive(:collect_errors_metric)
        described_class.collect_metrics(dummy_state, dummy_metric_data)
      end
    end
  end
end

describe D13n::Metric::Stream::StreamTracerHelpers::Namer do
  let(:dummy_module) { Module.new { include D13n::Metric::Stream::StreamTracerHelpers::Namer; extend self}}
  let(:dummy_type) { 'dummy_type'}
  let(:dummy_idc_name) {'hq'}
  let(:dummy_idc_env) {'stg'}
  let(:dummy_app_name) {'dummy_app'}
  let(:dummy_metric_data) { 
    {
      :name => :request,
      :uuid => 'abc'
    }
  }
  let(:dummy_ref_metric_data) {
    dummy_metric_data.merge({
      :referring_stream_id => 'bcd'
    })
  }

  let(:dummy_stream_basic_tags) { ["basic_tag:abc"]}
  before :each do
    allow(D13n).to receive(:idc_name).and_return(dummy_idc_name)
    allow(D13n).to receive(:idc_env).and_return(dummy_idc_env)
    allow(D13n).to receive(:app_name).and_return(dummy_app_name)

  end

  describe "#prefix" do
    it 'should return app.http.i prefix' do
      expect(dummy_module.prefix).to be_eql 'app.http.i'
    end
  end

  describe "#metric_name" do
    it 'should return app.http.i.dummy_type' do
      expect(dummy_module.metric_name(dummy_type)).to be_eql 'app.http.i.dummy_type'
    end
  end

  describe "stream_basic_tags" do
    it 'should return all basic tags without referring stream' do
      expect(dummy_module.stream_basic_tags(dummy_metric_data)).to be_eql [
        "idc:#{dummy_idc_name}",
        "env:#{dummy_idc_env}",
        "app:#{dummy_app_name}",
        "name:#{dummy_metric_data[:name]}",
        "uuid:#{dummy_metric_data[:uuid]}",
        "stream_id:#{dummy_metric_data[:uuid]}",
        "type:stream"
      ]
    end

    it 'should return all basic tags with referring stream' do
      expect(dummy_module.stream_basic_tags(dummy_ref_metric_data)).to be_eql [
        "idc:#{dummy_idc_name}",
        "env:#{dummy_idc_env}",
        "app:#{dummy_app_name}",
        "name:#{dummy_ref_metric_data[:name]}",
        "uuid:#{dummy_ref_metric_data[:uuid]}",
        "stream_id:#{dummy_ref_metric_data[:referring_stream_id]}",
        "type:span"
      ]
    end
  end

  describe "app metric tags" do
    before :each do
      allow(dummy_module).to receive(:stream_basic_tags).and_return(dummy_stream_basic_tags.dup)
    end
    describe "stream_duration_tags" do
      it 'should return duration tags' do
        expect(dummy_module.stream_duration_tags(dummy_metric_data)).to match_array dummy_stream_basic_tags << "time:duration"
      end
    end

    describe "stream_exclusive_tags" do
      it 'should return exclusive tags' do
        expect(dummy_module.stream_exclusive_tags(dummy_metric_data)).to match_array dummy_stream_basic_tags << "time:exclusive"
      end
    end

    describe "stream_request_tags" do
      it 'should return exclusive tags' do
        expect(dummy_module.stream_request_tags(dummy_metric_data)).to match_array dummy_stream_basic_tags
      end
    end

    describe "http metric" do
      let(:dummy_http_metric_data) { {
        :http_response_code => "200",
        :http_response_content_type => 'json',
        :http_response_content_length => 300
      }}

      describe "stream_http_response_code_tags" do
        it 'should return tags with code' do
          expect(dummy_module.stream_http_response_code_tags(dummy_http_metric_data)).to match_array (dummy_stream_basic_tags + ["response:code", "code:#{dummy_http_metric_data[:http_response_code]}"])
        end
      end

      describe "stream_http_response_type_tags" do
        it 'should return tags with type' do
          expect(dummy_module.stream_http_response_content_type_tags(dummy_http_metric_data)).to match_array (dummy_stream_basic_tags + ["response:type", "type:#{dummy_http_metric_data[:http_response_content_type]}"])
        end
      end

      describe "stream_http_response_length_tags" do
        it 'should return tags with code' do
          expect(dummy_module.stream_http_response_content_length_tags(dummy_http_metric_data)).to match_array dummy_stream_basic_tags << "response:length"
        end
      end
    end

    describe "stream_error_tags" do
      before :each do 
        @dummy_error = Class.new(ArgumentError) {
                                     def self.name
                                      "DummyError"
                                     end
                                }
        @dummy_error_instance = @dummy_error.new
      end

      context "when error is Class" do
        it 'should return error class name' do
          expect(dummy_module.stream_error_tags(dummy_metric_data, @dummy_error)).to match_array dummy_stream_basic_tags << "error:DummyError"
        end
      end

      context "when error is Class" do
        it 'should return error class name' do
          expect(dummy_module.stream_error_tags(dummy_metric_data, @dummy_error_instance)).to match_array dummy_stream_basic_tags << "error:DummyError"
        end
      end
    end

    describe "stream_apdex_tags" do
      let(:dummy_apdex_metric_data) { {:apdex_perf_zone => 't'}}
      it "should return apdex_zone tag" do
        expect(dummy_module.stream_apdex_tags(dummy_apdex_metric_data)).to match_array dummy_stream_basic_tags << "apdex_zone:#{dummy_apdex_metric_data[:apdex_perf_zone]}"
      end
    end
  end
end