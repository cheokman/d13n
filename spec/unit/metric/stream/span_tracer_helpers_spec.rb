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
      before :each do 
        allow(described_class).to receive(:collect_metrics)
      end
      context 'when duration less than max allowed metric duration' do
        before :each do
          allow(described_class).to receive(:get_timings).and_return([1000, 300])
          
        end
        context 'when duration larger than zero' do
          context 'when exclusive larger than zero' do
            it 'should collect metric' do
              described_class.trace_footer(dummy_state, 1000, 'first_name', dummy_frame, {})
            end
          end

          context 'when exclusive less than zero' do
            before :each do
              allow(described_class).to receive(:get_timings).and_return([1000, -300])
              allow(dummy_frame).to receive(:children_time).and_return(100)
            end

            it 'should collect metric' do
              expect(described_class).to receive(:collect_metrics)
              described_class.trace_footer(dummy_state, 1000, 'first_name', dummy_frame, {})
            end

            it 'should log in warn' do
              expect(D13n.logger).to receive(:warn)
              described_class.trace_footer(dummy_state, 1000, 'first_name', dummy_frame, {})
            end
          end
        end
        context 'when duration less than zero' do
          before :each do
            allow(described_class).to receive(:get_timings).and_return([-1000, 300])
          end

          it 'should collect metric' do
            expect(described_class).to receive(:collect_metrics)
            described_class.trace_footer(dummy_state, 1000, 'first_name', dummy_frame, {})
          end

          it 'should log in warn' do
            expect(D13n.logger).to receive(:warn)
            described_class.trace_footer(dummy_state, 1000, 'first_name', dummy_frame, {})
          end
        end
      end

      context 'when duration larger than max allowed metric duration' do
        before :each do
          allow(described_class).to receive(:get_timings).and_return([1_000_000_001, 300])
          allow(dummy_frame).to receive(:children_time).and_return(100)
        end
        it 'should not collect metric' do
          expect(described_class).not_to receive(:collect_metrics)
          described_class.trace_footer(dummy_state, 1000, 'first_name', dummy_frame, {})
        end

        it 'should log in warn' do
          expect(D13n.logger).to receive(:warn)
          described_class.trace_footer(dummy_state, 1000, 'first_name', dummy_frame, {})
        end
      end
    end
  end

  describe 'metric collector' do
    let(:dummy_collector) {double()}
    before :each do
      allow(dummy_collector).to receive(:measure)
      allow(dummy_collector).to receive(:increment)
      allow(described_class).to receive(:stream_duration_tags)
      allow(described_class).to receive(:stream_exclusive_tags)
      allow(described_class).to receive(:stream_request_tags)
      allow(D13n::Metric::Manager).to receive(:instance).and_return(dummy_collector)
    end

    describe '#collect_span_duration_timing' do
      it 'should call stream_duration_tags to create tags' do
        expect(described_class).to receive(:stream_duration_tags)
        described_class.collect_span_duration_timing(dummy_collector,dummy_state,'first_name',100, {}, {})
      end

      it 'should call measure to collect' do
        expect(dummy_collector).to receive(:measure)
        described_class.collect_span_duration_timing(dummy_collector,dummy_state,'first_name',100, {}, {})
      end
    end

    describe '#collect_span_exclusive_timing' do
      it 'should call stream_exclusive_tags to create tags' do
        expect(described_class).to receive(:stream_exclusive_tags)
        described_class.collect_span_exclusive_timing(dummy_collector,dummy_state,'first_name',100, {}, {})
      end
    
      it 'should call measure to collect' do
        expect(dummy_collector).to receive(:measure)
        described_class.collect_span_exclusive_timing(dummy_collector,dummy_state,'first_name',100, {}, {})
      end
    end

    describe '#collect_span_request_count' do
      it 'should call stream_request_tags to create tags' do
        expect(described_class).to receive(:stream_request_tags)
        described_class.collect_span_request_count(dummy_collector,dummy_state,'first_name', {}, {})
      end
    
      it 'should call measure to collect' do
        expect(dummy_collector).to receive(:increment)
        described_class.collect_span_request_count(dummy_collector,dummy_state,'first_name',{}, {})
      end
    end

    describe '#collect_metrics' do
      it 'should get collector' do
        expect(D13n::Metric::Manager).to receive(:instance)
        described_class.collect_metrics(dummy_state,'first_name', 100,100,{},{})
      end

      it 'should call collect_span_duration_timing' do
        expect(described_class).to receive(:collect_span_duration_timing)
        described_class.collect_metrics(dummy_state,'first_name', 100,100,{},{})
      end

      it 'should call collect_span_exclusive_timing' do
        expect(described_class).to receive(:collect_span_exclusive_timing)
        described_class.collect_metrics(dummy_state,'first_name', 100,100,{},{})
      end

      it 'should call collect_span_request_count' do
        expect(described_class).to receive(:collect_span_request_count)
        described_class.collect_metrics(dummy_state,'first_name', 100,100,{},{})
      end
    end
  end

  describe '#get_metric_data' do
   let(:dummy_stream) {double()}
    before :each do
      allow(dummy_state).to receive(:current_stream).and_return(dummy_stream)
      allow(dummy_stream).to receive(:generate_default_metric_data)
    end

    it 'should call stream to get metric data' do
      expect(dummy_stream).to receive(:generate_default_metric_data)
      described_class.get_metric_data(dummy_state, 0,0,{})
    end
  end
end