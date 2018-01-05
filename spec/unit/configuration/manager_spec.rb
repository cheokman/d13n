require 'spec_helper'

describe D13n::Configuration::Manager do
  before(:each) {@cm = described_class.new}

  context '#initialize before first key access' do
    it "has empty cache" do
      expect(@cm.instance_variable_get(:@cache)).to be_empty
    end

    it "has empty callbacks" do
      expect(@cm.instance_variable_get(:@callbacks)).to be_empty
    end

    it "has instance of environment source" do
      expect(@cm.instance_variable_get(:@environment_source)).to be_instance_of(D13n::Configuration::EnvironmentSource)
    end

    it "has nil of server source" do
      expect(@cm.instance_variable_get(:@server_source)).to be_nil
    end

    it "has nil of manual source" do
      expect(@cm.instance_variable_get(:@manual_source)).to be_nil
    end

    it "has nil of yaml source" do
      expect(@cm.instance_variable_get(:@yaml_source)).to be_nil
    end

    it "has instance of default source" do
      expect(@cm.instance_variable_get(:@default_source)).to be_instance_of(D13n::Configuration::DefaultSource)
    end
  end
  context '#register_callback' do
    let(:callback) {Proc.new {|value| observer_value1 = value}}
    let(:callback1) {Proc.new {|value| observer_value2 = value}}
   
    it 'add one callback Proc by key' do
      @cm.register_callback('key1', &callback)
      expect(@cm.instance_variable_get(:@callbacks)).to include('key1' => callback)
    end

    it 'add two callbacks Proc by key' do
      @cm.register_callback('key1', &callback)
      @cm.register_callback('key1', &callback1)
      expect(@cm.instance_variable_get(:@callbacks)).to include('key1' => [callback,callback1])
    end

    it 'callback called once' do
      allow(callback).to receive(:call)
      @cm.register_callback('key1', &callback)
      expect(callback).to have_received(:call)
    end
  end

  context '#invoke_callbacks' do
    let(:callback) {Proc.new {|value| observer_value = value}}
    before(:each) {
      @cm.instance_variable_set(:@cache, {key1: 1, key2: 2})
      @cm.instance_variable_set(:@callbacks, {key1: [callback]})
    }
    it 'return nil when source missing' do
      expect(@cm.invoke_callbacks('',nil)).to be_nil
    end

    context 'when value in cache and source is same' do
      it 'not invoke callback in add direction' do
        allow(callback).to receive(:call)
        @cm.invoke_callbacks(:add, {key1: 1})
        expect(callback).to_not have_received(:call)
      end

      it 'not invoke callback in other direction' do
        allow(callback).to receive(:call)
        @cm.invoke_callbacks(:other, {key1: 1})
        expect(callback).to_not have_received(:call)
      end
    end

    context 'when value in cache and source is different' do
      it 'invoke callback by source value add direction' do
        allow(callback).to receive(:call)
        @cm.invoke_callbacks(:add, {key1: 2})
        expect(callback).to have_received(:call).with(2)
      end

      it 'invoke callback by cache value add direction' do
        allow(callback).to receive(:call)
        @cm.invoke_callbacks(:other, {key1: 2})
        expect(callback).to have_received(:call).with(1)
      end
    end
  end

  context '#remove_config_type' do
    let(:srv_src) {D13n::Configuration::ServerSource.new({key1: 1, key2: 2})}
    before(:each) {
      allow(@cm).to receive(:reset_cache)
      allow(@cm).to receive(:invoke_callbacks)
      allow(@cm).to receive(:log_config)
      @cm.instance_variable_set(:@server_source, srv_src)
    }

    it 'remove :server config type' do
      @cm.remove_config_type(:server)
      expect(@cm.instance_variable_get(:@server_source)).to be_nil
    end
  end

  context '#replace_or_add_config' do
    let(:srv_src) {D13n::Configuration::ServerSource.new({key1: 1, key2: 2})}
    before(:each) {
      allow(@cm).to receive(:reset_cache)
      allow(@cm).to receive(:log_config)
      allow(@cm).to receive(:invoke_callbacks)
      @cm.replace_or_add_config(srv_src)
    }
    it 'invoke callback add' do
      expect(@cm).to have_received(:invoke_callbacks).with(:add, srv_src)
    end

    it 'reset cache' do
      expect(@cm).to have_received(:reset_cache)
    end

    it 'log add source' do
      expect(@cm).to have_received(:log_config).with(:add, srv_src)
    end

    it 'update server source' do
      expect(@cm.instance_variable_get(:@server_source)).to be_eql(srv_src)
    end
  end

  context '#fetch' do
    let(:config_stack) {
      [
        {key1: 1, key2: 2},
        {key2: 3, key3: 3, key5: 5},
        {key4: 1, key1: 2, key2: 1}
      ]
    }

    before(:each) {
      allow(@cm).to receive(:config_stack).and_return(config_stack)
    }

    it 'default 1 return for key4' do
      expect(@cm[:key4]).to be_eql 1
    end

    it 'override 1 return for key1' do
      expect(@cm[:key1]).to be_eql 1
    end

    it 'value 5 return for key5' do
      expect(@cm[:key5]).to be_eql 5
    end
  end
end