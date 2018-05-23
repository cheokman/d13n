require 'spec_helper'
require 'd13n/metric/stream/stream_tracer_helpers'
describe D13n::Metric::Stream::StreamTracerHelpers do
  
end
describe D13n::Metric::Stream::StreamTracerHelpers::Namer do
  let (:dummy_module) { Module.new { include D13n::Metric::Stream::StreamTracerHelpers::Namer; extend self}}
  before :each do
  end

  describe "#prefix" do
    it 'should return app.http.i prefix' do
      expect(dummy_module.prefix).to be_eql 'app.http.i'
    end
  end
end