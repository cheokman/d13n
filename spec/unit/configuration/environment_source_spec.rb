require 'spec_helper'

describe D13n::Configuration::EnvironmentSource do
    before(:each) {
      allow(D13n).to receive(:app_prefix).and_return('FAKE')
      allow(D13n).to receive(:app_name).and_return('fake')
      @es = described_class.new
    }

  describe '#set_log_file' do
    let (:stdout) { 'STDOUT' }
    let (:app_log) {'FAKE_LOG'}
    let (:app_log_path) {'log'}
    let (:app_log_full_path) {'/home/user/log'}
    let (:app_log_file_name) {'fake.log'}

    
    context "unset FAKE_LOG" do
      it 'has empty log_file_path' do
        expect(@es[:log_file_path]).to be_nil
      end

      it 'has empty log_file_name' do
        expect(@es[:log_file_name]).to be_nil
      end
    end

    context 'set FAKE_LOG STDOUT' do
      before(:each) { 
        stub_const('ENV', {app_log => stdout})
        @es.set_log_file 
      }
      it 'has STDOUT log_file_path' do
        expect(@es[:log_file_path]).to be_eql stdout
      end

      it 'has STDOUT log_file_name' do
        expect(@es[:log_file_name]).to be_eql stdout
      end
    end

    context 'set FAKE_LOG stdout' do
      before(:each) { 
        stub_const('ENV', {app_log => stdout.downcase})
        @es.set_log_file 
      }

      it 'has STDOUT log_file_path' do
        expect(@es[:log_file_path]).to be_eql stdout
      end

      it 'has STDOUT log_file_name' do
        expect(@es[:log_file_name]).to be_eql stdout
      end
    end

    context "set FAKE_LOG full path /home/user/.fake/fake.log" do
      let(:config_file) {File.join(app_log_full_path, app_log_file_name)}
      before(:each) { 
        stub_const('ENV', {app_log => config_file})
        @es.set_log_file 
      }

      it 'has /home/user/log log_file_path' do
        expect(@es[:log_file_path]).to be_eql app_log_full_path
      end

      it 'has fake.log log_file_name' do
        expect(@es[:log_file_name]).to be_eql app_log_file_name
      end
    end
    context "set FAKE_LOG path log/fake.log" do
      let(:config_file) {File.join(app_log_path, app_log_file_name)}
      before(:each) { 
        stub_const('ENV', {'FAKE_LOG' => config_file})
        @es.set_log_file 
      }

      it 'has user log_file_path' do
        expect(@es[:log_file_path]).to be_eql app_log_path
      end

      it 'has axle.log log_file_name' do
        expect(@es[:log_file_name]).to be_eql app_log_file_name
      end
    end
  end
  describe '#set_config_file' do
    let(:config_path) {'/home/user/.fake'}
    context "unset FAKE_CONFIG" do
      it 'has empty config_path' do
        expect(@es[:config_path]).to be_nil
      end
    end

    context "set FAKE_CONFIG /home/user/.fake" do
      before(:each) { 
        stub_const('ENV', {'FAKE_CONFIG' => config_path})
        @es.set_config_file 
      }
      it 'has /home/user/.fake config_path' do
        expect(@es[:config_path]).to be_eql config_path
      end
    end
  end

  describe '#collect_axle_environment_variable_keys' do
    context "unset ENV" do
      before(:each) {
        stub_const('ENV', {})
      }

      subject {@es.collect_app_environment_variable_keys}

      it {is_expected.to be_empty}
    end

    context "set ENV {'fake_a' => 'a', 'FAKE_B' => 'b', 'c' => 'd'}" do
      before(:each) {
        stub_const('ENV', {'fake_a' => 'a', 'FAKE_B' => 'b', 'c' => 'd'})
      }

      subject {@es.collect_app_environment_variable_keys}

      it {is_expected.to include('fake_a')}
      it {is_expected.to include('FAKE_B')}
      it {is_expected.not_to include('c')}
    end
  end

  describe '#convert_environment_key_to_config_key' do
    before(:each) { stub_const('D13n::Configuration::EnvironmentSource::SUPPORTED_PREFIXES', Proc.new {/^fake_a_|^fake_c_/i}) }

    it 'has convert fake_a_c to :c' do
      expect(@es.convert_environment_key_to_config_key("fake_a_c")).to be_eql(:c)
    end

    it 'has convert fake_c_d to :d' do
      expect(@es.convert_environment_key_to_config_key("fake_c_d")).to be_eql(:d)
    end
  end

  describe '#set_key_by_type' do
    let(:env_key) {'FAKE_KEY'}
    let(:config_key) {:key}
    let(:string_value) {'string'}
    let(:integer_value) { '12' }
    let(:float_value) { '1.2' }
    let(:symbol_value) { 'symbol' }
    let(:false_value) { 'false' }
    let(:off_value) { 'off' }
    let(:no_value) { 'no' } 

    context 'string key type with value string' do
      before(:each) { 
        stub_const('ENV', {env_key => string_value})
        allow(@es.type_map).to receive(:[]).with(config_key).and_return(String)
      }

      it {
        @es.set_key_by_type(config_key, env_key)   
        expect(@es).to include(config_key => 'string') 
      }
    end

    context 'integer key type with value 12' do
      before(:each) { 
        stub_const('ENV', {env_key => integer_value})
        allow(@es.type_map).to receive(:[]).with(config_key).and_return(Integer)
      }

      it {
        @es.set_key_by_type(config_key, env_key)   
        expect(@es).to include(config_key => 12) 
      }
    end

    context 'float key type with value 1.2' do
      before(:each) { 
        stub_const('ENV', {env_key => float_value})
        allow(@es.type_map).to receive(:[]).with(config_key).and_return(Float)
      }

      it {
        @es.set_key_by_type(config_key, env_key)   
        expect(@es).to include(config_key => 1.2) 
      }
    end

    context 'symbol key type with value :symbol' do
      before(:each) { 
        stub_const('ENV', {env_key => symbol_value})
        allow(@es.type_map).to receive(:[]).with(config_key).and_return(Symbol)
      }

      it {
        @es.set_key_by_type(config_key, env_key)   
        expect(@es).to include(config_key => :symbol) 
      }
    end

    context 'boolean type with value false' do
      before(:each) { 
        stub_const('ENV', {env_key => false_value})
        allow(@es.type_map).to receive(:[]).with(config_key).and_return(D13n::Configuration::Boolean)
      }

      it {
        @es.set_key_by_type(config_key, env_key)   
        expect(@es).to include(config_key => false) 
      }
    end

    context 'boolean type with value off' do
      before(:each) { 
        stub_const('ENV', {env_key => off_value})
        allow(@es.type_map).to receive(:[]).with(config_key).and_return(D13n::Configuration::Boolean)
      }

      it {
        @es.set_key_by_type(config_key, env_key)   
        expect(@es).to include(config_key => false) 
      }
    end

    context 'boolean type with value no' do
      before(:each) { 
        stub_const('ENV', {env_key => no_value})
        allow(@es.type_map).to receive(:[]).with(config_key).and_return(D13n::Configuration::Boolean)
      }

      it {
        @es.set_key_by_type(config_key, env_key)   
        expect(@es).to include(config_key => false) 
      }
    end

    context 'boolean type with value true' do
      before(:each) { 
        stub_const('ENV', {env_key => 'true'})
        allow(@es.type_map).to receive(:[]).with(config_key).and_return(D13n::Configuration::Boolean)
      }

      it {
        @es.set_key_by_type(config_key, env_key)   
        expect(@es).to include(config_key => true) 
      }
    end

    context 'boolean type with else value' do
      before(:each) { 
        stub_const('ENV', {env_key => 'else'})
        allow(@es.type_map).to receive(:[]).with(config_key).and_return(D13n::Configuration::Boolean)
      }

      it {
        @es.set_key_by_type(config_key, env_key)   
        expect(@es).to include(config_key => true) 
      }
    end
  end
end