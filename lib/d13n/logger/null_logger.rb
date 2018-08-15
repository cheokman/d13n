module D13n
  class Logger
    class NullLogger
      include Singleton
      def fatal(*args); end
      def error(*args); end
      def warn(*args);  end
      def info(*args);  end
      def debug(*args); end

      def method_missing(method, *args, &blk)
        nil
      end
    end
  end
end