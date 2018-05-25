require 'spec_helper'
require 'd13n/metric'
require 'd13n/metric/instrumentation/sinatra/stream_namer'
describe D13n::Metric::Instrumentation::Sinatra::StreamNamer do
  context '.for_route' do
    let(:dummy_env) { {'sinatra.route' => 'dummy_route'}}
    let(:no_key_env) { {}}
    let(:dummy_request) { double() }
    it 'should return rount sinatra.route in env' do
      expect(described_class.for_route(dummy_env, dummy_request)).to be_eql('dummy_route')
    end

    it 'should return nil in env without key sinatra.route' do
      expect(described_class.for_route(no_key_env, dummy_request)).to be_nil
    end
  end
end