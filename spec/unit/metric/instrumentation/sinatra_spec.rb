require 'spec_helper'
require 'd13n/metric'
require 'd13n/metric/instrumentation/sinatra'

describe D13n::Metric::Instrumentation::Sinatra do
  class DummyApp
    include D13n::Metric::Instrumentation::Sinatra
  end

  let(:dummy_app) { DummyApp }
  let(:dummy_app_instance) { DummyApp.new }
  describe '.auto_middleware_enable?' do
    context 'when metric.app.sintra.auto_middleware.enable false' do
      
      before :each do
        allow(D13n.config).to receive(:[]).with(:'metric.app.sinatra.auto_middleware.enable').and_return(false)
      end

      it 'should be false' do
        expect(DummyApp.send(:auto_middleware_enable?)).to be_falsy
      end
    end

    context 'when metric.app.sintra.auto_middleware.enable true' do
      
      before :each do
        allow(D13n.config).to receive(:[]).with(:'metric.app.sinatra.auto_middleware.enable').and_return(true)
      end

      it 'should be false' do
        expect(DummyApp.send(:auto_middleware_enable?)).to be_truthy
      end
    end
  end

  describe '.try_to_use' do
    context 'when app no support middleware' do
      let(:app) { double('app') }
      let(:clazz) { double('class')}
      before(:each) do
        allow(app).to receive(:middleware).and_return(nil)
      end
      it 'should return nil' do
        expect(dummy_app.send(:try_to_use, app, clazz)).to be_nil
      end
    end

    context 'when app support middleware' do
      let(:app) { double('app')}
      let(:clazz) { double('clazz')}
      let(:middleware) { [[clazz,'a']]}
      let(:new_clazz) { double('new_clazz') }

      before(:each) do
        allow(app).to receive(:middleware).and_return(middleware)
        allow(app).to receive(:use)
      end

      context 'when class is in middleware' do
        it 'should not use' do
          expect(app).not_to receive(:use)
          dummy_app.send(:try_to_use, app, clazz)
        end
      end

      context 'when new class is not in middleware' do
        it 'should use' do
          expect(app).to receive(:use).with(new_clazz)
          dummy_app.send(:try_to_use, app, new_clazz)
        end
      end
    end
  end

  describe 'included class' do
    subject { dummy_app }
    it { is_expected.to respond_to(:websocket_with_d13n_instrumentation)}
    it { is_expected.to respond_to(:build_with_d13n_instrumentation)}
  end

  describe 'included class' do
    subject { dummy_app_instance }

  
    it { is_expected.to respond_to(:process_route_with_d13n_instrumentation)}
    it { is_expected.to respond_to(:dispatch_with_d13n_instrumentation)}
    it { is_expected.to respond_to(:dispatch_and_notice_errors_with_d13n_instrumentation)}
  end

  describe '.d13n_middlewares' do
    context 'when middleware enable true' do
      before :each do
        allow(D13n::Rack::MetricMiddleware).to receive(:enabled?).and_return(true)
      end

      subject { dummy_app.d13n_middlewares }
      it { is_expected.not_to be_empty }
      it { is_expected.to include D13n::Rack::MetricMiddleware }
    end

    context 'when middleware enable false' do
      before :each do
        allow(D13n::Rack::MetricMiddleware).to receive(:enabled?).and_return(false)
      end

      subject { dummy_app.d13n_middlewares }
      it { is_expected.to be_empty }
    end
  end

  describe '.build_with_d13n_instrumentation' do
    let(:middleware) { double() }
    before :each do
      allow(dummy_app).to receive(:try_to_use)
      allow(dummy_app).to receive(:build_without_d13n_instrumentation)
      allow(dummy_app).to receive(:d13n_middlewares).and_return([middleware])
    end
    context 'when auto_middle_ware enable false' do
      before :each do
        allow(dummy_app).to receive(:auto_middleware_enable?).and_return(false)
      end

      it 'should not use d13n middlewares' do
        expect(dummy_app).not_to receive(:try_to_use)
        dummy_app.build_with_d13n_instrumentation
      end

      it 'should call original build' do
        expect(dummy_app).to receive(:build_without_d13n_instrumentation)
        dummy_app.build_with_d13n_instrumentation
      end
    end

    context 'when auto_middle_ware enable true' do
      before :each do
        allow(dummy_app).to receive(:auto_middleware_enable?).and_return(true)
      end

      it 'should not use d13n middlewares' do
        expect(dummy_app).to receive(:try_to_use)
        dummy_app.build_with_d13n_instrumentation
      end

      it 'should call original build' do
        expect(dummy_app).to receive(:build_without_d13n_instrumentation)
        dummy_app.build_with_d13n_instrumentation
      end
    end
  end

  describe '.process_route_with_d13n_instrumentation' do
    before :each do
      allow(dummy_app_instance).to receive(:env)
      allow(dummy_app_instance).to receive(:process_route_without_d13n_instrumentation)
      RSpec::Mocks.configuration.allow_message_expectations_on_nil = true
    end

    context 'when exception occurred' do
      it 'should log the information in logger debug level' do
        expect(D13n.logger).to receive(:debug)
        dummy_app_instance.process_route_with_d13n_instrumentation
      end

      it 'should call original process_route' do
        expect(dummy_app_instance).to receive(:process_route_without_d13n_instrumentation)
        dummy_app_instance.process_route_with_d13n_instrumentation
      end
    end

    context 'when first argument given' do
      it 'should assign first argument as last rount in env' do
        expect(dummy_app_instance.env).to receive(:[]=).with('d13n.last_route', 'dummy_route')
        dummy_app_instance.process_route_with_d13n_instrumentation('dummy_route')
      end

      it 'should call original process_route' do
        expect(dummy_app_instance).to receive(:process_route_without_d13n_instrumentation)
        dummy_app_instance.process_route_with_d13n_instrumentation
      end
    end
  end

  describe '.route_eval_with_d13n_instrumentation' do
    before :each do
      allow(dummy_app_instance).to receive(:route_eval_without_d13n_instrumentation)
    end

    context 'when stream_name nil' do
      before :each do
        allow(D13n::Metric::Instrumentation::Sinatra::StreamNamer).to receive(:for_route).and_return(nil)
      end

      it 'should not call set_default_stream_name' do
        expect(::D13n::Metric::Stream).not_to receive(:set_default_stream_name)
        dummy_app_instance.route_eval_with_d13n_instrumentation
      end

      it 'should call route_eval_without_d13n_instrumentation' do
        expect(dummy_app_instance).to receive(:route_eval_without_d13n_instrumentation)
        dummy_app_instance.route_eval_with_d13n_instrumentation
      end
    end

    context 'when stream_name not nil' do
      before :each do
        allow(dummy_app_instance).to receive(:env)
        allow(dummy_app_instance).to receive(:request)
        allow(D13n::Metric::Instrumentation::Sinatra::StreamNamer).to receive(:for_route).and_return('dummy_name')
        allow(::D13n::Metric::Stream).to receive(:set_default_stream_name)
      end
        
      it 'should call set_default_stream_name for stream' do
        expect(::D13n::Metric::Stream).to receive(:set_default_stream_name)
        dummy_app_instance.route_eval_with_d13n_instrumentation
      end

      it 'should call route_eval_without_d13n_instrumentation' do
        expect(dummy_app_instance).to receive(:route_eval_without_d13n_instrumentation)
        dummy_app_instance.route_eval_with_d13n_instrumentation
      end
    end

    context 'when raise error' do
      before :each do
        allow(D13n::Metric::Instrumentation::Sinatra::StreamNamer).to receive(:for_route).and_return('dummy_name')
        allow(::D13n::Metric::Stream).to receive(:set_default_stream_name)
      end

      it 'should call route_eval_without_d13n_instrumentation' do
        expect(dummy_app_instance).to receive(:route_eval_without_d13n_instrumentation)
        dummy_app_instance.route_eval_with_d13n_instrumentation
      end
    end
  end

  describe '#dispatch_with_d13n_instrumentation' do
    let(:dummy_request_params) { double("dummy_request_params") }
    let(:dummy_request) { double('dummy_request') }
    let(:dummy_filter_params) { double('dummy_filter_params')}
    before :each do
      allow(dummy_app_instance).to receive(:get_request_params).and_return(dummy_request_params)
      allow(dummy_app_instance).to receive(:request).and_return(dummy_request)
      allow(D13n::Metric::Instrumentation::Sinatra::StreamNamer).to receive(:initial_stream_name).and_return('dummy_name')
      allow(dummy_app_instance).to receive(:get_filter_parames).and_return(dummy_filter_params)
      allow(dummy_app_instance).to receive(:perform_action_with_d13n_stream)
    end

    it 'should call perform_action_with_d13n_stream' do
      expect(dummy_app_instance).to receive(:perform_action_with_d13n_stream)
      dummy_app_instance.dispatch_with_d13n_instrumentation
    end
  end

  describe '#get_request_params' do
    let(:dummy_request) { double() }
    context 'when normal' do
      before :each do
        allow(dummy_request).to receive(:params).and_return("dummy_params")
        dummy_app_instance.instance_variable_set(:@request, dummy_request)
      end

      it 'should return dummy params' do
        expect(dummy_app_instance.get_request_params).to be_eql "dummy_params"
      end
    end

    context 'when error' do
      before :each do
        allow(dummy_request).to receive(:params).and_raise
        dummy_app_instance.instance_variable_set(:@request, dummy_request)
      end

      it 'should not raise error' do
        expect {dummy_app_instance.get_request_params}.not_to raise_error
      end

      it 'should return ni' do
        expect(dummy_app_instance.get_request_params).to be_nil
      end

      it 'should logger in debug' do
        expect(D13n.logger).to receive(:debug)
        dummy_app_instance.get_request_params
      end
    end
  end
end