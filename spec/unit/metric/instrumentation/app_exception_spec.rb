require 'spec_helper'
require 'd13n/metric'
require 'd13n/metric/instrumentation/app_exception'

describe D13n::Metric::Instrumentation::AppException do

  describe 'before perform' do
    let(:kls) {D13n::Error}

    it "should not have instrumentation" do
      expect(kls).not_to respond_to :exception_with_d13n_instrumentation
    end
  end

  describe "after perform" do
    before :each do 
      allow_any_instance_of(D13n::Metric::Instrumentation::AppException).to receive(:enable?).and_return(true)
      D13n::Metric::Instrumentation::Conductor.perform!
    end

    it "can raise D13n::Error" do
      expect {raise D13n::Error.new('error')}.to raise_error D13n::Error
    end
  end


end