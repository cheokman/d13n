require 'spec_helper'
require 'd13n/metric'
require 'd13n/metric/instrumentation/exception'

describe D13n::Metric::Instrumentation::Exception do
  class NormalError < StandardError
    include D13n::Metric::Instrumentation::Exception
  end

  class D13nTestError < D13n::Error
    include D13n::Metric::Instrumentation::Exception
  end

  describe 'enable?' do
    describe 'null config' do
      before(:each) do
        allow(D13n.config).to receive(:[]).with(:'metric.app.state.exception.enable').and_return(nil)
      end

      it 'should return false' do
        expect(described_class.enable?).to be_falsy 
      end
    end

    describe 'true string config' do
      before(:each) do
        allow(D13n.config).to receive(:[]).with(:'metric.app.state.exception.enable').and_return('true')
      end

      it 'should return false' do
        expect(described_class.enable?).to be_truthy
      end
    end

    describe 'true boolean config' do
      before(:each) do
        allow(D13n.config).to receive(:[]).with(:'metric.app.state.exception.enable').and_return(true)
      end

      it 'should return false' do
        expect(described_class.enable?).to be_truthy
      end
    end

    describe 'included class' do
      it 'should have class methods' do
        expect(NormalError).to respond_to(:exception_with_d13n_instrumentation)
      end

      it 'should have instance methods' do
        expect(NormalError.new).to respond_to(:exception_with_d13n_instrumentation)
      end

      describe 'd13n error' do
        before(:each) do
          allow(D13nTestError).to receive(:exception_without_d13n_instrumentation)
          allow_any_instance_of(D13nTestError).to receive(:exception_without_d13n_instrumentation)
        end
        
        it 'should have d13n_error_inherated true' do
          expect(D13nTestError.d13n_error_inherated?).to be_truthy
        end

        describe 'exception_with_d13n_instrumentation' do
          it 'should return without instrumentation' do
            expect(D13n::Metric::Manager).not_to receive(:instance)
            D13nTestError.exception_with_d13n_instrumentation
          end

          it 'should return without instrumentation' do
            expect(D13n::Metric::Manager).not_to receive(:instance)
            D13nTestError.new.exception_with_d13n_instrumentation
          end
        end
      end

      describe 'not d13n error' do
        let(:fake_manager) { double("manager") }
        let(:fake_metric) { double("metric") }
        let(:fake_processor) { double("processor")}
        before(:each) do
          allow(fake_processor).to receive(:process)
          allow(fake_metric).to receive(:instance) { fake_processor }
          allow(fake_manager).to receive(:metric) { fake_metric }
          allow(D13n::Metric::Manager).to receive(:instance) {fake_manager}
          allow(NormalError).to receive(:exception_without_d13n_instrumentation)
          allow_any_instance_of(NormalError).to receive(:exception_without_d13n_instrumentation)
        end

        it 'should have d13n_error_inherated false' do
          expect(NormalError.d13n_error_inherated?).to be_falsy
        end

        describe 'exception_with_d13n_instrumentation' do
          it 'should return without instrumentation' do
            expect(D13n::Metric::Manager).to receive(:instance)
            NormalError.exception_with_d13n_instrumentation
          end

          it 'should return without instrumentation' do
            expect(D13n::Metric::Manager).to receive(:instance)
            NormalError.new.exception_with_d13n_instrumentation
          end

          describe 'when metric not found' do
            before :each do
              allow(fake_manager).to receive(:metric).and_return(nil)
            end
            it 'should call exception_without_d13n_instrumentation' do
              
              expect(NormalError).to receive(:exception_without_d13n_instrumentation)
              NormalError.new.exception_with_d13n_instrumentation
            end

            it 'should log information' do
              expect(D13n.logger).to receive(:info)
              NormalError.new.exception_with_d13n_instrumentation
            end
          end
        end
      end
    end
  end
end