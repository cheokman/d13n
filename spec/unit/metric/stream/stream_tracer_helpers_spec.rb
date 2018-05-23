require 'spec_helper'
require 'd13n/metric/stream/stream_tracer_helpers'
describe D13n::Metric::Stream::StreamTracerHelpers do
  
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
        :http_response_type => 'json',
        :http_response_lenght => 300
      }}

      describe "stream_http_response_code_tags" do
        it 'should return tags with code' do
          expect(dummy_module.stream_http_response_code_tags(dummy_http_metric_data)).to match_array (dummy_stream_basic_tags + ["response:code", "code:#{dummy_http_metric_data[:http_response_code]}"])
        end
      end

      describe "stream_http_response_type_tags" do
        it 'should return tags with type' do
          expect(dummy_module.stream_http_response_content_type_tags(dummy_http_metric_data)).to match_array (dummy_stream_basic_tags + ["response:type", "type:#{dummy_http_metric_data[:http_response_type]}"])
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
  end
end