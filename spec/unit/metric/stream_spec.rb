require 'spec_helper'
require 'd13n/metric'
require 'd13n/metric/stream'

describe D13n::Metric::Stream do
  let(:described_instance) { described_class.new("dummy_category", {:stream_name => 'dummy_sream'})}
  describe '#make_stream_name' do
    before :each do
      allow(D13n::Metric::Instrumentation::ControllerInstrumentation::StreamNamer).to receive(:prefix_for_category).and_return('dummy_category')
    end

    it 'should return #{category}.#{name} stream name' do
      expect(described_instance.make_stream_name("service.get_player")).to be_eql "dummy_category.service.get_player"
    end
  end

  describe '#name_last_frame' do
    let(:dummy_frame) { double() }
    let(:dummy_frame_stack) {[dummy_frame]}

    before :each do
      allow(dummy_frame).to receive(:name=)
      described_instance.instance_variable_set(:@frame_stack, dummy_frame_stack)
      
    end

    it 'should update name of last frame' do
      expect(dummy_frame).to receive(:name=).with('dummy')
      described_instance.name_last_frame('dummy')
    end
  end

  describe '#set_default_stream_name' do
    context 'when category nil' do
      before :each do
        described_instance.set_default_stream_name('dummy', nil)
      end

      it 'should have dummy default name' do
        expect(described_instance.instance_variable_get(:@default_name)).to be_eql("dummy")
      end

      it 'should have unchanged category' do
        expect(described_instance.instance_variable_get(:@category)).to be_eql("dummy_category")
      end
    end

    context 'when category not nil' do
      before :each do
        described_instance.set_default_stream_name('dummy', 'updated_category')
      end

      it 'should have dummy default name' do
        expect(described_instance.instance_variable_get(:@default_name)).to be_eql("dummy")
      end

      it 'should have updated_category category' do
        expect(described_instance.instance_variable_get(:@category)).to be_eql("updated_category")
      end
    end
  end

  describe '.set_default_stream_name' do
    before :each do
      allow(described_class).to receive(:st_current).and_return(described_instance)
      allow(described_instance).to receive(:name_last_frame)
      allow(described_instance).to receive(:make_stream_name)
      allow(described_instance).to receive(:set_default_stream_name)
    end

    it 'should call name_last_frame' do
      expect(described_instance).to receive(:name_last_frame)
      described_class.set_default_stream_name('service.get_player')
    end

    it 'should call make_stream_name' do
      expect(described_instance).to receive(:make_stream_name)
      described_class.set_default_stream_name('service.get_player')
    end

    it 'should call set_default_stream_name' do
      expect(described_instance).to receive(:set_default_stream_name)
      described_class.set_default_stream_name('service.get_player')
    end
  end
end