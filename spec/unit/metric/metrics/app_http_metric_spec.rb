require 'spec_helper'
require 'd13n/metric'
require 'd13n/metric/metrics'
describe D13n::Metric::AppHttpMetric::Namespace do
  context 'valid service and endpoint' do
    before :each do
      @kls = Class.new {include D13n::Metric::AppHttpMetric::Namespace}
      @request = double()
      allow(@request).to receive(:uri)
      allow(D13n::Metric::Helper).to receive(:service_for).and_return('fake_service')
      allow(D13n::Metric::Helper).to receive(:endpoint_for).and_return('fake_endpoint')
    end

    it 'return service and endpoint pair' do
      expect(@kls.new.get_service_endpoint(@request)).to be_eql ['fake_service', 'fake_endpoint']
    end
  end

  context 'invalid service and endpoint' do
    before :each do
      @kls = Class.new {include D13n::Metric::AppHttpMetric::Namespace}
      @request = double()
      allow(@request).to receive(:uri).and_return('fake')
    end

    it 'raise ServiceNotFound for service error' do
      allow(D13n::Metric::Helper).to receive(:service_for).and_return(nil)
      allow(D13n::Metric::Helper).to receive(:endpoint_for).and_return('fake_endpoint')
      expect {@kls.new.get_service_endpoint(@request)}.to raise_error D13n::Metric::ServiceNotFound
    end

    it 'raise EndpointNotFound for service error' do
      allow(D13n::Metric::Helper).to receive(:service_for).and_return('fake_service')
      allow(D13n::Metric::Helper).to receive(:endpoint_for).and_return(nil)
      expect { @kls.new.get_service_endpoint(@request) }.to raise_error D13n::Metric::EndpointNotFound
    end
  end

  context '#service_metric' do
    before :each do
      @kls = Class.new {include D13n::Metric::AppHttpMetric::Namespace}
      @instance = @kls.new
      @prefix = 'idc0.axle.int0'
      @service = 'fake'
      @type = :count
      @request = double()
      allow(@instance).to receive(:prefix).and_return(@prefix)
      allow(@instance).to receive(:get_service_endpoint).and_return([@service, 'endpoint'])
    end

    it 'return dotted metric' do
      expect(@instance.service_metric(@request, @type)).to be_eql('idc0.axle.int0.service.fake.count')
    end
  end

  context '#endpoint_metric' do
    before :each do
      @kls = Class.new {include D13n::Metric::AppHttpMetric::Namespace}
      @instance = @kls.new
      @prefix = 'idc0.axle.int0'
      @service = 'fake'
      @endpoint = 'post'
      @type = :count
      @request = double()
      allow(@instance).to receive(:prefix).and_return(@prefix)
      allow(@instance).to receive(:get_service_endpoint).and_return([@service, @endpoint])
    end

    it 'return dotted metric' do
      expect(@instance.endpoint_metric(@request, @type)).to be_eql('idc0.axle.int0.endpoint.fake.post.count')
    end
  end

  context 'metric tags' do
    before :each do
      @kls = Class.new {include D13n::Metric::AppHttpMetric::Namespace}
      @instance = @kls.new
      @prefix = 'idc0.axle.int0'
      @service = 'fake'
      @endpoint = 'post'
      @type = :count
      @request = double()
      @response = double()
      @idc = 'hqidc'
      @env = 'dev'
      @app = 'd13n'
      @code = 400
      allow(@instance).to receive(:get_service_endpoint).and_return([@service, @endpoint])
      allow(D13n).to receive(:idc_name).and_return(@idc)
      allow(D13n).to receive(:idc_env).and_return(@env)
      allow(D13n).to receive(:app_name).and_return(@app)
      
    end

    context '#http_basic_tags' do
      it 'return tags array' do
        expect(@instance.http_basic_tags(@request)).to be_eql ["idc:#{@idc}","env:#{@env}","app:#{@app}","srv:#{@service}","endpoint:#{@endpoint}"]
      end
    end

    context '#http_status_tags' do
      before(:each) do
        allow(@response).to receive(:code).and_return(@code)
      end

      it 'return tags array' do
        expect(@instance.http_status_tags(@request, @response)).to be_eql ["idc:#{@idc}","env:#{@env}","app:#{@app}","srv:#{@service}","endpoint:#{@endpoint}","status:#{@code}"]
      end
    end

    context '#http_error_tags' do
      before(:each) do
        allow(@response).to receive(:code).and_return(@code)
      end

      it 'return tags array' do
        expect(@instance.http_status_tags(@request, @response)).to be_eql ["idc:#{@idc}","env:#{@env}","app:#{@app}","srv:#{@service}","endpoint:#{@endpoint}","status:#{@code}"]
      end

    end
  end
end

describe D13n::Metric::AppHttpMetric::Out do
  before :each do
    @kls = Class.new {include D13n::Metric::AppHttpMetric::Out}
    @instance = @kls.new
    @collector = double()
    @instance.instance_variable_set(:@collector, @collector)
    @state = double()
    @stack = double()
    @node = double()
    @request = double()
    allow(@state).to receive(:traced_stack).and_return(@stack)
  end

  describe '#start' do
    it 'return nil when any exception' do
      allow(@stack).to receive(:push_frame).and_raise Exception
      expect(@instance.start(@state, Time.now, '')).to be_nil
      expect {@instance.start(@state, Time.now, '')}.not_to raise_error 
    end
  end

  describe '#finish' do
    
  end

  describe 'collect metric' do
    before :each do
      allow(@instance).to receive(:service_metric).and_return("idc0.env0.fams")
      allow(@instance).to receive(:endpoint_metric).and_return("idc0.env0.fams.bet")
      allow(@instance).to receive(:metric_name).and_return("app.http.o")
      allow(@instance).to receive(:http_basic_tags).and_return(["idc:moidc","env:stg0","app:axle"])
      allow(@instance).to receive(:http_status_tags).and_return(["idc:moidc","env:stg0","app:axle", "status:400"])
      allow(@instance).to receive(:http_error_tags).and_return(["idc:moidc","env:stg0","app:axle", "error:name_error"])
    end

    it 'call collector on request count' do
      expect(@collector).to receive(:increment).with(any_args).once
      @instance.collect_request_count(@request)
    end

    it 'call collector on request timing' do
      expect(@collector).to receive(:measure).with(any_args).once
      @instance.collect_request_timing(@request, 1.0)
    end
  end
end

describe D13n::Metric::AppHttpMetric do
  describe '.check_direction' do
    before(:each) do
      stub_const("PROCESSOR", {'in' => 1,'out' => 2})
    end

    context 'direction in PROCESSOR' do
      it 'does not raise exception' do
        expect { described_class.check_direction('in')}.not_to raise_error
      end
    end

    context 'direction not in PORCESSOR' do
      it 'raises exception' do
        expect { described_class.check_direction('inl')}.to raise_error(D13n::Metric::InstrumentNameError)
      end
    end
  end

  describe '#prefix' do
    context 'in http request' do
      before(:each) do
        @instance = described_class.new(nil, :direction => 'in')
      end

      it 'return in counter prefix' do
        expect(@instance.prefix).to be_eql('app.http.i')
      end
    end

    context 'out http rquest' do
      before(:each) do
        @instance = described_class.new(nil, :direction => 'out')
      end

      it 'return in counter prefix' do
        expect(@instance.prefix).to be_eql('app.http.o')
      end
    end
  end
end