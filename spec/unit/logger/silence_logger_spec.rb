require 'spec_helper'

describe D13n::Logger::SilenceLogger do
  subject {described_class.new}
  context 'all instance logger methods' do
    it {is_expected.to respond_to :fatal}
    it {is_expected.to respond_to :error}
    it {is_expected.to respond_to :warn}
    it {is_expected.to respond_to :info}
    it {is_expected.to respond_to :debug}
  end
end