require 'spec_helper'

describe D13n::Configuration::DottedHash do
  let(:fake_hash) { {'a' => {'b' => 'c'}} }
  describe '#symbolize' do
    before(:each) { @string_hash = {'a' => {'b' => 'c'}}}
    it "change first level string key to symbole only" do
      described_class.symbolize(@string_hash)
      expect(@string_hash).to be_eql({:a => {'b' => 'c'}})
    end
  end

  context "keep nesting for #{{'a' => {'b' => 'c'}}}" do
    let(:nesting_hash) {
      {
       :a => {'b' => 'c'},
       :'a.b' => 'c' 
      }
    }
    before(:each) { @string_hash = {'a' => {'b' => 'c'}} }

    subject {described_class.new @string_hash, true}

    it {is_expected.to be_eql nesting_hash} 
  end

  context "no keep nesting for #{{'a' => {'b' => 'c'}}}" do
    let(:no_nesting_hash) {
      {
       :'a.b' => 'c' 
      }
    }
    before(:each) { @string_hash = {'a' => {'b' => 'c'}} }

    subject {described_class.new @string_hash}

    it {is_expected.to be_eql no_nesting_hash} 
  end
end