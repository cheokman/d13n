require 'spec_helper'
require 'd13n/metric'
require 'd13n/metric/instrumentation/app_exception'

describe D13n::Metric::Instrumentation::AppException do
  describe "after perform" do
    before :each do
      allow(D13n::Metric::Instrumentation::AppException).to receive(:enable?).and_return(true)
      D13n::Metric::Instrumentation::Conductor.perform!
    end

    it "can raise D13n::Error" do
      expect {raise D13n::Error.new('error')}.to raise_error D13n::Error
    end

    describe 'class method' do
      it "should have instrumentation with d13n" do
        expect(D13n::Error).to respond_to(:exception_with_d13n_instrumentation)
      end

      it "should have instrumentation without d13n" do
        expect(D13n::Error).to respond_to(:exception_without_d13n_instrumentation)
      end

      it 'should have original exception alias' do
        expect(D13n::Error.method(:exception_without_d13n_instrumentation).original_name).to be_eql(:exception)
      end

      it 'should have new exception alias' do
        expect(D13n::Error.method(:exception).original_name).to be_eql(:exception_with_d13n_instrumentation)
      end
    end

    describe 'instance methods' do
      let(:instance) {D13n::Error.new}

      it "should have instrumentation with d13n" do
        expect(instance).to respond_to(:exception_with_d13n_instrumentation)
      end

      it "should have instrumentation without d13n" do
        expect(instance).to respond_to(:exception_without_d13n_instrumentation)
      end

      it 'should have original exception alias' do
        expect(instance.method(:exception_without_d13n_instrumentation).original_name).to be_eql(:exception)
      end

      it 'should have new exception alias' do
        expect(instance.method(:exception).original_name).to be_eql(:exception_with_d13n_instrumentation)
      end
    end
  end
end