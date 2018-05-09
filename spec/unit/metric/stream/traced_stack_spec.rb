require 'spec_helper'
require 'd13n/metric/stream/traced_stack'
describe D13n::Metric::Stream::StackFrame do
  before :each do
    @start_time = Time.now
    @instance = described_class.new('http', @start_time)
  end

  it 'assign tag' do
    expect(@instance.tag).to be_eql 'http'
  end

  it 'assig start time' do
    expect(@instance.start_time).to be_eql @start_time
  end

  it 'init children time' do
    expect(@instance.children_time).to be_eql 0
  end
end

describe D13n::Metric::Stream::TracedStack do
  before :each do
    @instance = described_class.new
    @state = double()
    @tag = 'http'
    @time = Time.now.to_f
  end

  describe '.new' do
    it 'init empty stack' do
      expect(@instance.instance_variable_get(:@stack)).to be_empty
    end
  end

  describe '#push_frame' do
    context 'with time' do
      it 'push as stack frame' do
        frame = @instance.push_frame(@state, @tag, @time)
        expect(frame).to be_kind_of D13n::Metric::Stream::StackFrame
      end

      it 'is the last of stack' do
        frame = @instance.push_frame(@state, @tag, @time)
        expect(@instance.last).to be_eql(frame)
      end
    end
  end

  describe '#last' do
    before :each do
      @frame = @instance.push_frame(@state, @tag, @time)
    end

    it 'return last frame' do
      expect(@instance.last).to be_eql @frame
    end
  end

  describe '#clear' do
    before :each do
      @frame = @instance.push_frame(@state, @tag, @time)
      @instance.clear
    end

    it 'is clear' do
      expect(@instance.empty?).to be_truthy
    end
  end

  describe '#fetch_matching_frame' do
    before :each do
      @expected_frame = nil
      @last_frame = nil
      @expected_position = 4
      @stack_size = 8
      @stack_size.times { |i|
        @last_frame = @instance.push_frame(@state, 'http')
        @expected_frame = @last_frame if i == @expected_position
      }
      @unexpected_frame = D13n::Metric::Stream::StackFrame.new('http', 1501059108.048553)
    end

    context 'expected_frame is the last one' do
      it 'return last one' do
        last_frame = @instance.last
        expect(@instance.fetch_matching_frame(@last_frame)).to be_eql last_frame
      end

      it 'not info log' do
        expect(D13n.logger).not_to receive(:info)
        @instance.fetch_matching_frame(@last_frame)
      end
    end

    context 'expected_frame is not the last one' do
      it 'return not last expected_frame' do
        last_frame = @instance.last
        expect(@instance.fetch_matching_frame(@expected_frame)).not_to be_eql last_frame
      end

      it 'pop all frame before expected_frame' do
        @instance.fetch_matching_frame(@expected_frame)
        stack = @instance.instance_variable_get(:@stack)
        expect(stack.size).to be_eql @expected_position
      end
    end

    context 'unexpected_frame' do
      it 'pop all frame' do
        expect { @instance.fetch_matching_frame(@unexpected_frame)}.to raise_error D13n::Metric::Stream::UnexpectedStackError
        expect(@instance.empty?).to be_truthy
      end
    end
  end

  describe '#note_children_time' do
    before :each do
      @start_time = 1501059108.048553
      @call_time = 500.00
      @child_frame_children_time = 300.00
      @current_time = @start_time + @call_time
      
      @child_frame = D13n::Metric::Stream::StackFrame.new('http', @start_time)
      @child_frame.children_time = @child_frame_children_time
    end

    context 'stack not empty' do
      before :each do
        @parent_frame = @instance.push_frame(@state, 'http')
      end

      context 'deduct_call_time_from_parent is true' do
        it 'deducts call time' do
          @instance.note_children_time(@child_frame, @current_time,true)
          expect(@parent_frame.children_time).to be_eql @call_time
        end
      end

      context 'deduct_call_time_from_parent is false' do
        it 'assign child time from current frame' do
          @instance.note_children_time(@child_frame, @current_time,false)
          expect(@parent_frame.children_time).to be_eql @child_frame_children_time
        end
      end
    end

    context 'stack empty' do
      it 'skip process' do
        expect {@instance.note_children_time(@child_frame, @current_time, true)}.not_to raise_error
      end
    end
  end

  it 'is empty' do
    expect(@instance.empty?).to be_truthy
  end
end