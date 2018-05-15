module D13n::Metric
  class Stream
    class UnexpectedStackError < D13n::Error;end
    class StackFrame
      attr_reader :tag
      attr_accessor :name, :start_time, :children_time, :end_time
      def initialize(tag, start_time)
        @tag = tag
        @start_time = start_time
        @children_time = 0
      end
    end

    class TracedStack
      def initialize
        @stack = []
      end

      def push_frame(state, tag, time = Time.now.to_f)
        frame = StackFrame.new(tag, time)
        @stack.push frame
        frame
      end

      def pop_frame(state, expected_frame, name, time, deduct_call_time_from_parent=true)
        frame = fetch_matching_frame(expected_frame)
        frame.end_time = time
        frame.name = name
        
        note_children_time(frame, time, deduct_call_time_from_parent)

        frame
      end

      def fetch_matching_frame(expected_frame)
        while frame = @stack.pop
          if frame == expected_frame
            return frame
          else
            D13n.logger.info("Unexpected frame in traced method stack: #{frame.inspect} expected to be #{expected_frame.inspect}")
          end
        end
        raise UnexpectedStackError.new "Frame not found in stack: #{expected_frame.inspect}"
      end

      def note_children_time(frame, time, deduct_call_time_from_parent)
        if !@stack.empty?
          if deduct_call_time_from_parent
            @stack.last.children_time += (time - frame.start_time)
          else
            @stack.last.children_time += frame.children_time
          end
        end
      end

      def empty?
        @stack.empty?
      end

      def clear
        @stack.clear
      end

      def last
        @stack.last
      end
    end
  end
end
