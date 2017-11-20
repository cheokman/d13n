require 'spec_helper'
require 'd13n/configuration/default_source'
require 'd13n/service'

describe D13n::Configuration::DefaultSource do
  before(:each) do
    @default_source = {
      :fake => {
          :default => 1000,
          :public => true,
          :type => Integer,
          :description => 'Define fake config'
      },
    }

    module FakeApp;end
    module FakeApp
      class Service < D13n::Service;end
    end
  end

  describe '.deafults=' do
    before :each do
      described_class.defaults=@default_source
    end

    it 'can add application default source' do
      expect(described_class.defaults).to include @default_source
    end
  end

  describe '#config_search_paths' do
    subject {described_class.config_search_paths.call}
    context 'when no root and APP_ROOT config' do
      it { 
           allow(D13n.service.instance).to receive(:root).and_return(false)
           allow(ENV).to receive(:[]).with("HOME").and_return(false)
           is_expected.to be_eql(["config/fake_app.yml","fake_app.yml"])
         }
    end

    context 'when root config as /root' do
      it {
        allow(D13n.service.instance).to receive(:root).and_return('/root')
        allow(ENV).to receive(:[]).with("HOME").and_return(false)
        is_expected.to be_eql(["config/fake_app.yml","fake_app.yml","/root/config/fake_app.yml","/root/fake_app.yml"])
      }
    end

    context 'when APP_ROOT config as /home/user' do
      it {
        allow(D13n.service.instance).to receive(:root).and_return('/root')
        allow(ENV).to receive(:[]).with("HOME").and_return('/home/user')
        is_expected.to be_eql(["config/fake_app.yml",
                                      "fake_app.yml",
                             "/root/config/fake_app.yml",
                                    "/root/fake_app.yml",
                     "/home/user/.fake_app/fake_app.yml",
                           "/home/user/fake_app.yml"])
      }
    end
  end

  describe '#config_path' do
    subject {described_class.config_path.call}
    context "no config file found" do
      it {
        allow(D13n).to receive(:config).and_return({:config_search_paths => ["config/fake_app.yml","fake_app.yml","/root/config/fake_app.yml","/root/fake_app.yml"]})
        allow(File).to receive(:exist?).and_return(false)
        is_expected.to be_eql ""
      }
    end

    context "one config file found in config/fake_app.yml" do
      it {
        allow(D13n).to receive(:config).and_return({:config_search_paths => ["config/fake_app.yml","fake_app.yml","/root/config/fake_app.yml","/root/fake_app.yml"]})
        allow(File).to receive(:exist?).with("config/fake_app.yml").and_return(true)
        is_expected.to be_eql "config/fake_app.yml"
      }
    end
  end


 describe '#default_values' do
    let(:fake_default) {   
                         {
                          :log_level => {:default => 'info'}, 
                          :config_path => {:default =>'/root/fake_app.yml'}
                         }
                        }
    before { 
      stub_const("D13n::Configuration::DEFAULTS", fake_default)
      allow_any_instance_of(described_class).to receive(:frozen_default)
    }

    subject {described_class.new.defaults}

    it {
      is_expected.to be_eql({log_level: 'info', config_path: '/root/fake_app.yml'})}
  end

  describe '#default_alias' do
    let(:fake_default) {
                         {
                          :log_level => {:default => 'info', :alias => 'lg'}, 
                          :config_path => {:default =>'/root/fake_app.yml'}
                         }
    }
    before {
      stub_const("D13n::Configuration::DEFAULTS", fake_default)
      allow_any_instance_of(described_class).to receive(:frozen_default)
    }

    subject {described_class.new.alias}

    it { is_expected.to be_eql({log_level: 'lg', config_path: 'config_path'})}
  end

end