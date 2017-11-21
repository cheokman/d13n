require 'spec_helper'

describe D13n::Configuration::YamlSource do
  let (:yml_file) {
"
common: &default_settings
  # Your application name. Renaming here affects where data displays
  app_name: <%= app_name %>

  # Logging level for log/axle.log
  log_level: info

# Environment-specific settings are in this section.
# RAILS_ENV or RACK_ENV (as appropriate) is used to determine the environment.
# If your application has other named environments, configure them here.
development:
  <<: *default_settings
  app_name: <%= app_name %> (Development)

  # NOTE: There is substantial overhead when running in developer mode.
  # Do not use for production or load testing.
  developer_mode: true

test:
  <<: *default_settings
  # It doesn't make sense
  monitor_mode: false
"     
  }

  before(:each) { 
    allow(D13n.logger).to receive(:info).and_return(nil)
    allow(File).to receive(:read).and_return(yml_file)
    @ys = described_class.new("fake_yml",:test)
  }

  describe '#validate_config_file' do
    context 'when empty path' do
      it "return nil" do
        expect(@ys.send(:validate_config_file, "")).to be_nil
      end
    end

    context 'when file path not exit' do
      before(:each) {allow(File).to receive(:exist?).and_return(false)}
      it "return nil" do
        expect(@ys.send(:validate_config_file,"fake_yml")).to be_nil
      end
    end

    context 'when normal' do
      before(:each) { 
        allow(File).to receive(:expand_path).and_return('/fake_path/fake_yml') 
        allow(File).to receive(:exist?).and_return(true)
      }

      it 'return correct expand_path' do
        expect(@ys.send(:validate_config_file, 'fake_yml')).to be_eql '/fake_path/fake_yml'
      end
    end
  end

  describe '#process_erb' do
    it 'substract comments with #' do
      expect(@ys.send(:process_erb, '# this is a comment')).to be_eql '#'
    end

    it 'bind with app name in no comment' do
      allow(@ys).to receive(:app).and_return("fake_app")
      expect(@ys.send(:process_erb,"app: <%= app %>")).to be_eql('app: fake_app')
    end

    it 'can\'t bind with app name in comment' do
      allow(@ys).to receive(:app).and_return("fake_app")
      expect(@ys.send(:process_erb,"# <%= app %>")).to be_eql('#')
    end
  end

  describe '#process_yaml' do
    let(:fake_yml) {
      "
      common: &default_settings
        app_name: fake_app
        log_level: info

      development:
        <<: *default_settings
        app_name: fake_app (Development)
        developer_mode: true

      test:
        <<: *default_settings
        monitor_mode: false
      "
    }

    let(:fake_config) {
      { 'app_name' => 'fake_app',
        'log_level' => 'info',
        'monitor_mode' => false
      }
      }


    before(:each) {allow(@ys).to receive(:app_name).and_return("fake_app")}
    context 'env exist' do
      it 'return test env config' do
        
        expect(@ys.send(:process_yaml, fake_yml, "test", {}, 'fake_path')).to be_eql fake_config
      end
    end

    context 'env not exist' do
      it 'return empty config' do
        allow(@ys).to receive(:log_failure)
        expect(@ys.send(:process_yaml, fake_yml, "test1", {}, 'fake_path')).to be_empty
      end

      it 'log failure with logger error call' do
        logger = double()
        allow(logger).to receive(:error)
        allow(D13n).to receive(:logger).and_return(logger)
        @ys.send(:process_yaml, fake_yml, "test1", {}, 'fake_path')
        expect(D13n.logger).to have_received(:error).with("Config file at fake_path doesn't include a 'test1' section!")
      end

      it 'log failure with failures array' do
        logger = double()
        allow(logger).to receive(:error)
        allow(D13n).to receive(:logger).and_return(logger)
        @ys.send(:process_yaml, fake_yml, "test1", {}, 'fake_path')
        expect(@ys.failures).to be_eql [["Config file at fake_path doesn't include a 'test1' section!"]]
      end
    end
  end

end