require 'spec_helper'
require 'd13n/application/class_methods'

describe D13n::Application::ClassMethods do
  before(:each) do
    @fake_app = Class.new {
      def self.name
        "FakeApp"
      end
      extend D13n::Application::ClassMethods
    }
    @fake_app.reset
  end
  
  it 'shoule have D13n Configurator' do
    expect(@fake_app.config).to be_kind_of D13n::Configuration::Manager
  end

  it 'assign self as application in D13n' do
    expect(D13n.application).to be_eql(@fake_app)
  end

  it 'access application itself' do
    expect(@fake_app.application).to be_eql(@fake_app)
  end

  it 'should have fake_app name' do
    expect(@fake_app.app_name).to be_eql('fake_app')
  end

  it 'should have FAKE_APP prefix' do
    expect(@fake_app.app_prefix).to be_eql('FAKE_APP')
  end
  
  it 'can change config' do
    fake_config = double()
    @fake_app.config = fake_config

    expect(@fake_app.config).to be_eql fake_config
  end

  it 'access logger as D13n.logger' do
    expect(@fake_app.logger).to be_eql D13n.logger
  end

  it 'can change logger' do
    fake_logger = double()
    @fake_app.logger = fake_logger

    expect(@fake_app.logger).to be_eql(fake_logger)
  end

  it 'access default source' do
    expect(@fake_app.default_source).to be_eql D13n::Configuration::DefaultSource.defaults
  end

  # it 'assign default source' do
  #   allow_any_instance_of(D13n::Configuration::DefaultSource).to receive(:frozen_default).and_return
  #   @fake_app.default_source = {
  #     :fake_config1 => {:key1 => 'v1'},
  #     :fake_config2 => {:key2 => 'v2'}
  #   }
  # end
end