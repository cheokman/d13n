require 'spec_helper'

describe D13n::Configuration::ServerSource do
  before :all do
    @default_hash = {
      :test1 => {
        :type => String
      },

      :test2 => {
        :type => D13n::Configuration::Boolean
      }
    }
    
  end

  describe '.new' do
    before :each do
      allow_any_instance_of(described_class).to receive(:type_map).and_return({:test1 => String, :test2 => D13n::Configuration::Boolean})
      @instance = described_class.new({:test1 => 1, :test2 => 'true'})
      @instance.set_keys_by_type
    end

    it 'can convert string type' do
      expect(@instance[:test1]).to be_eql '1'
    end

    it 'can convert boolean type' do
      expect(@instance[:test2]).to be_eql true
    end
  end
end