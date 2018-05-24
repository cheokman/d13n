require 'spec_helper'
require 'd13n/metric'
require 'd13n/metric/stream/stream_tracer_helpers'
require 'd13n/metric/stream/span_tracer_helpers'
describe D13n::Metric::Stream::SpanTracerHelpers do
  let(:dummy_state) {double()}
  let(:dummy_stack) {double()}
  let(:dummy_frame) {double()}

  before :each do
    allow(dummy_stack).to receive(:push_frame)
    allow(dummy_state).to receive(:trace_span_stack).and_return(dummy_stack)
    allow(dummy_state).to receive(:push_frame)
    allow(dummy_stack).to receive(:pop_frame).and_return(dummy_frame)
  end

  describe "#trace_header" do
    it 'should call state trace_span_stack' do
      expect(dummy_state).to receive(:trace_span_stack)
      described_class.trace_header(dummy_state, 1)
    end

    it 'should call stack push_frame' do
      expect(dummy_stack).to receive(:push_frame)
      described_class.trace_header(dummy_state, 1)
    end
  end

  describe '#get_timings' do
    before :each do
      allow(dummy_frame).to receive(:children_time).and_return(10)
    end

    it "should return duration and exclusive timing" do
      expect(described_class.get_timings(20,100,dummy_frame)).to match_array [80,70]
    end
  end

  describe '#trace_footer' do
    let(:t0) { 10000 }
    before :each do
      allow(Time).to receive(:now).and_return(10030)
      allow(described_class).to receive(:get_metric_data)
      allow(described_class).to receive(:get_timings)
    end

    context 'when nil expected_frame' do
      it 'should not collect metric' do
        expect(described_class).not_to receive(:collect_metric)
        described_class.trace_footer(dummy_state, 1000, 'first_name', nil, {})
      end
    end

    context 'when not nil expected_frame' do
      context 'when duration less than max allowed metric duration' do
        before :each do
          allow(described_class).to receive(:get_timings).and_return([1000, 300])
          allow(described_class).to receive(:collect_metrics)
        end
        context 'when duration larger than zero' do
          context 'when exclusive larger than zero' do
            it 'should collect metric' do
              expect(described_class).to receive(:collect_metrics)
              described_class.trace_footer(dummy_state, 1000, 'first_name', dummy_frame, {})
            end
          end
        end
      end
    end
  end
end