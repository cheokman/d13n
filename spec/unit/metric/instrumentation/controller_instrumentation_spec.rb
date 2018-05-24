require 'spec_helper'
require 'd13n/metric'
require 'd13n/metric/instrumentation/controller_instrumentation'

describe D13n::Metric::Instrumentation::ControllerInstrumentation::StreamNamer do
  let(:traced_obj_kls) {
    Class.new {
      def self.name
        "TracedKls"
      end
    }
  }

  let(:traced_obj_mod) {
    Module.new {
      def self.name
        "TracedMod"
      end
    }
  }

  let(:not_name_lks) {
    Class.new {}
  }
  before :each do
    
  end

  describe "kls_name" do
    let(:class_name_opt) { {:class_name => "ClassOpt"}}
    let(:empty_opt) {{}}
    context "when class_name given in options" do
      it 'should return class_name in options' do
        expect(described_class.kls_name(traced_obj_kls, class_name_opt)).to be_eql "ClassOpt"
      end
    end

    context "when class_name is not given in options" do
      context "when traced_obj is a class" do
        it 'should return class name with underscore' do
          expect(described_class.kls_name(traced_obj_kls, empty_opt)).to be_eql("traced_kls")
        end
      end

      context "when traced_obj is a module" do
        it 'should return module name with underscore' do
          expect(described_class.kls_name(traced_obj_mod, empty_opt)).to be_eql("traced_mod")
        end
      end

      context "when unnamed traced object" do
        it 'should return nil' do
          expect(described_class.kls_name(not_name_lks, empty_opt)).to be_eql nil
        end
      end
    end
  end

  describe "namespace" do
    let(:namespace_opt) {{:namespace => "dummy_namespace"}}
    let(:name_opt) {{:name => "dummy_name"}}
    before :each do 
      allow(described_class).to receive(:kls_name).and_return('dummy_class')
    end
    context "when namespace given in options" do
      it 'should return namespace in options' do
        expect(described_class.namespace(traced_obj_kls, namespace_opt)).to be_eql "dummy_namespace"
      end
    end

    context "when namespace is not given in options" do
      context 'when name given in options' do
        context 'when nil class name' do
          before :each do
            allow(described_class).to receive(:kls_name).and_return(nil)
          end

          it 'should return name as namespace' do
            expect(described_class.namespace(traced_obj_kls, name_opt)).to be_eql 'dummy_name'
          end
        end

        context 'when return class name' do
          it 'should return class name dotted with name' do
            expect(described_class.namespace(traced_obj_kls, name_opt)).to be_eql 'dummy_class.dummy_name'
          end
        end
      end

      context 'when name not given in options' do
        context "when object have d13n_metric_namespace" do
          let(:obj_with_method) { Class.new {
            def self.d13n_metric_namespace
              "method_namespace"
            end
          }}

          it 'should return namespace in d13n_metric_namespace method' do
            expect(described_class.namespace(obj_with_method)).to be_eql "method_namespace"
          end
        end

        context "when object have not d13n_metric_namespace" do
          it "should return class name as namespace" do
            expect(described_class.namespace(traced_obj_kls)).to be_eql "dummy_class"
          end
        end
      end
    end
  end

  describe 'prefix_for_category' do
    before :each do
      @stream = double()
    end

    context 'when nil category' do
      context 'when stream assigned category with sinatra' do
        before :each do
          allow(@stream).to receive(:category).and_return(:sinatra)
        end

        it 'should return sinatra prefix' do
          expect(described_class.prefix_for_category(@stream)).to be_eql ::D13n::Metric::Stream::SINATRA_PREFIX
        end
      end

      context 'when stream assigned not recongized category' do
        before :each do
          allow(@stream).to receive(:category).and_return(:unknown)
        end
        it 'shoild return nil' do
          expect(described_class.prefix_for_category(@stream)).to be_eql 'unknown'
        end
      end
    end

    context 'when not nil category' do
      context 'when known category sinatra' do
        it "should return sinatra" do
          expect(described_class.prefix_for_category(@stream, :sinatra)).to be_eql ::D13n::Metric::Stream::SINATRA_PREFIX
        end
      end

      context "when unknown category" do
        it "should return unknow" do
          expect(described_class.prefix_for_category(@stream, :unknown)).to be_eql 'unknown'
        end
      end
    end
  end

  describe 'name_for' do
    let(:stream) {double()}
    let(:obj) {double()}
    before :each do
      allow(described_class).to receive(:prefix_for_category).and_return('dummy_prefix')
      allow(described_class).to receive(:namespace).and_return('dummy_namespace')
    end

    it 'should join prefix and namespace with dot' do
      expect(described_class.name_for(stream, obj, :dummy)).to be_eql 'dummy_prefix.dummy_namespace'
    end
  end
end

describe D13n::Metric::Instrumentation::ControllerInstrumentation do
  let(:dummy_request) { double() }
  let(:dummy_opt_request) { double() }
  let(:dummy_request_args) { [{:request => dummy_opt_request}]}
  let(:dummy_empty_args) { [{}]}
  before :each do 
    @dummy_class = Class.new
    @dummy_class.include(described_class)
  end

  describe '#metric_request' do
    before :each do
      allow_any_instance_of(@dummy_class).to receive(:request).and_return(dummy_request)
    end

    context 'when args has request hash' do
      it 'should return request in args' do
        expect(@dummy_class.new.send(:metric_request, dummy_request_args)).to be_eql dummy_opt_request
      end
    end

    context 'when args has not request hash' do
      it 'should return request in args' do
        expect(@dummy_class.new.send(:metric_request, dummy_empty_args)).to be_eql dummy_request
      end
    end
  end

  describe '#create_stream_options' do
    let (:dummy_request) { double() }
    let (:dummy_params) {double()}
    before :each do
      allow(D13n::Metric::Instrumentation::ControllerInstrumentation::StreamNamer).to receive(:name_for).and_return 'dummy_name'
    end
    context 'when request in trace_options' do
      it 'should get request options from trace_options' do
        expect(@dummy_class.new.send(:create_stream_options, {:request => dummy_request}, nil, nil)).to include({:request => dummy_request})
      end
    end

    context 'when no request in trace_options' do
      before :each do
        allow_any_instance_of(@dummy_class).to receive(:request).and_return(dummy_request)
      end

      it 'should get request from dummy class' do
        expect(@dummy_class.new.send(:create_stream_options, {}, nil, nil)).to include({:request => dummy_request})
      end
    end

    context 'when params in trance_options' do
      it 'should have filtered_params in return' do
        expect(@dummy_class.new.send(:create_stream_options, {:params => dummy_params}, nil, nil)).to include({:filtered_params => dummy_params})
      end
    end

    it 'should have stream name in return' do
      expect(@dummy_class.new.send(:create_stream_options, {}, nil, nil)).to include({:stream_name => 'dummy_name'})
    end
  end

  describe '#perform_action_with_d13n_stream' do
    let(:dummy_state) { double() }
    before :each do
      @dummy_class.class_eval {
        def dummy_action;end

        def dummy_action_with_hook
          perform_action_with_d13n_stream(:category => "dummy",
                                          :request => {},
                                          :filtered_params => {}) do
                                            dummy_action
                                          end
        end
      }
      allow_any_instance_of(@dummy_class).to receive(:metric_request).and_return(dummy_request)
      allow_any_instance_of(@dummy_class).to receive(:create_stream_options).and_return({})
      allow(dummy_state).to receive(:request=)
    end

    context 'when http in tracable false' do
      before :each do
        allow(::D13n::Metric::Helper).to receive(:http_in_tracable?).and_return(false)
      end

      it 'should return without call hook' do
        @dummy_class.new.dummy_action_with_hook
        expect(D13n::Metric::Stream).not_to receive(:start)
      end
    end
  end
end