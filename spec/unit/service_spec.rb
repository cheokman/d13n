require 'spec_helper'

describe D13n::Service do
  before(:each) do
    module FakeApp
      class Service < D13n::Service; end
    end
  end

  it 'should assign self to D13n service' do
    expect(D13n.service).to be_eql FakeApp::Service
  end

  it 'should have instance method' do
    expect(FakeApp::Service).to respond_to(:instance)
  end

  it 'should have run! method' do
    expect(FakeApp::Service).to respond_to(:run!)
  end

  it 'should have app_class method' do
    expect(FakeApp::Service).to respond_to(:app_class)
  end

  it 'should return FakeApp when call app_class' do
    expect(FakeApp::Service.app_class).to be_eql(FakeApp)
  end

  it 'should return instance from instace method' do
    expect(FakeApp::Service.instance).to be_instance_of(FakeApp::Service)
  end

  describe "initialize" do
    let(:instance) {FakeApp::Service.new}
    it 'should be started false' do
      expect(instance.started).to be_falsy
    end

    it 'should have FAKE_APP app_prefix' do
      expect(instance.service_prefix).to be_eql('FAKE_APP')
    end
  end

  describe 'determine_service_conf' do
    before(:each) do
      @instance = FakeApp::Service.new
    end

    describe "when empty hash opt" do
      before(:each) do
        @instance.determine_service_conf
      end

      it "should have default 3000 port" do
        expect(@instance.service_conf[:port]).to be_eql(3000)
      end

      it "should have default binding localhost" do
        expect(@instance.service_conf[:bind]).to be_eql('localhost')
      end
    end

    describe "when port config" do
      before(:each) do
        @instance.determine_service_conf({:port => 3001})
      end

      it "should have 3001 port" do
        expect(@instance.service_conf[:port]).to be_eql(3001)
      end

      it "should have default binding localhost" do
        expect(@instance.service_conf[:bind]).to be_eql('localhost')
      end
    end

    describe "when binding host config" do
      before(:each) do
        @instance.determine_service_conf({:host => 'myhost.local'})
      end

      it "should have default 3000 port" do
        expect(@instance.service_conf[:port]).to be_eql(3000)
      end

      it "should have binding myhost.local" do
        expect(@instance.service_conf[:bind]).to be_eql('myhost.local')
      end
    end

    describe "when host and port config" do
      before(:each) do
        @instance.determine_service_conf({:port => 3002, :host => 'myhost2.local'})
      end

      it "should have 3002 port" do
        expect(@instance.service_conf[:port]).to be_eql(3002)
      end

      it "should have binding myhost2.local" do
        expect(@instance.service_conf[:bind]).to be_eql('myhost2.local')
      end
    end
  end

  describe 'default_env' do
    let(:instance) {FakeApp::Service.new}
    before(:each) do
      
    end

    describe "when app_prefix env set" do
      before(:each) do
        allow(ENV).to receive(:[]).with("FAKE_APP_ENV").and_return("test")
      end
      it "should output according to app_prefix env" do
        expect(instance.send(:default_env)).to be_eql("test")
      end
    end

    describe "when app_prefix env not set and RACK_ENV set" do
      before(:each) do
        allow(ENV).to receive(:[]).with("FAKE_APP_ENV").and_return(nil)
        allow(ENV).to receive(:[]).with("RACK_ENV").and_return("test1")
      end

      it "should output according to RACK_ENV" do
        expect(instance.send(:default_env)).to be_eql("test1")
      end
    end

    describe "when app_prefix and RACK_ENV not set" do
      it "should return default development" do
        expect(instance.send(:default_env)).to be_eql("development")
      end
    end
  end

  describe 'determine_env' do
    before(:each) do
      @instance = FakeApp::Service.new
      allow(@instance).to receive(:default_env).and_return("development")
    end

    describe "when empty opt" do
      before(:each) do
        @instance.determine_env
      end
      it 'should return default_env' do
        expect(@instance.env).to be_eql("development")
      end
    end

    describe "when env set in opt" do
      before(:each) do
        @instance.determine_env({:env => 'test1'})
      end

      it 'should return setting env test1' do
        expect(@instance.env).to be_eql("test1")
      end
    end
  end
end