require 'spec_helper'
require 'd13n/metric'
require 'd13n/metric/instrumentation/app_exception'

describe D13n::Metric::Instrumentation::AppException do
  class FakeError < D13n::Error
    include D13n::Metric::Instrumentation::AppException
  end

  class MetricTestError < D13n::Metric::MetricError
    include D13n::Metric::Instrumentation::AppException
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
        expect(FakeError).to respond_to(:exception_with_d13n_instrumentation)
      end

      it 'should have instance methods' do
        expect(FakeError.new).to respond_to(:exception_with_d13n_instrumentation)
      end

      describe 'not metric error' do
        before(:each) do
          allow(FakeError).to receive(:exception_without_d13n_instrumentation)
          allow_any_instance_of(FakeError).to receive(:exception_without_d13n_instrumentation)
        end
        
        it 'should have metric_error_inherated false' do
          expect(FakeError.metric_error_inherated?).to be_falsy
        end

        describe 'exception_with_d13n_instrumentation' do
          it 'should return without instrumentation' do
            expect(D13n::Metric::Manager).not_to receive(:instance)
            FakeError.exception_with_d13n_instrumentation
          end

          it 'should return without instrumentation' do
            expect(D13n::Metric::Manager).not_to receive(:instance)
            FakeError.new.exception_with_d13n_instrumentation
          end
        end
      end

      describe 'metric error' do
        let(:fake_manager) { double("manager") }
        let(:fake_metric) { double("metric") }
        let(:fake_processor) { double("processor")}
        before(:each) do
          allow(fake_processor).to receive(:process)
          allow(fake_metric).to receive(:instance) { fake_processor }
          allow(fake_manager).to receive(:metric) { fake_metric }
          allow(D13n::Metric::Manager).to receive(:instance) {fake_manager}
          allow(MetricTestError).to receive(:exception_without_d13n_instrumentation)
          allow_any_instance_of(MetricTestError).to receive(:exception_without_d13n_instrumentation)
        end

        it 'should have metric_error_inherated false' do
          expect(MetricTestError.metric_error_inherated?).to be_truthy
        end

        describe 'exception_with_d13n_instrumentation' do
          it 'should return without instrumentation' do
            expect(D13n::Metric::Manager).to receive(:instance)
            MetricTestError.exception_with_d13n_instrumentation
          end

          it 'should return without instrumentation' do
            expect(D13n::Metric::Manager).to receive(:instance)
            MetricTestError.new.exception_with_d13n_instrumentation
          end

          describe 'when metric not found' do
            before :each do
              allow(fake_manager).to receive(:metric).and_return(nil)
            end
            it 'should call exception_without_d13n_instrumentation' do
              
              expect(MetricTestError).to receive(:exception_without_d13n_instrumentation)
              MetricTestError.new.exception_with_d13n_instrumentation
            end

            it 'should log information' do
              expect(D13n.logger).to receive(:info)
              MetricTestError.new.exception_with_d13n_instrumentation
            end
          end
        end
      end
    end
  end
end