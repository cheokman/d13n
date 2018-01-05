# encoding: utf-8
module D13n
  class Logger
    module LogOnce
      NUM_LOG_ONCE_KEYS = 1000

      def log_once(level, key, *msgs)
        return if @already_logged.include?(key)

        if @already_logged.size >= NUM_LOG_ONCE_KEYS && key.kind_of?(String)
          return
        end

        @already_logged[key] = true

        self.send(level, *msgs)
      end

      def clear_already_logged
        @already_logged = {}
      end
    end
  end
end