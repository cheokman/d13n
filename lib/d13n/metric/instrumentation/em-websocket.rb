require 'd13n/metric/instrumentation/websocket_instrumentation'
D13n::Metric::Instrumentation::Conductor.direct do
  named :'em-websocket'

  depend_on do
    defined?(::EventMachine) && defined?(::EventMachine::WebSocket) &&
    defined?(::EventMachine::WebSocket::Connection) && 
    ::EventMachine::WebSocket::Connection.instance_methods.include?(:onmessage) &&
    ::EventMachine::WebSocket::Connection.instance_methods.include?(:onclose) &&
    ::EventMachine::WebSocket::Connection.instance_methods.include?(:onopen)
  end

  performances do
    D13n.logger.info 'Installing em-websocket instrumentation'
  end

  performances do
    ::EventMachine::WebSocket::Connection.class_eval do
      include D13n::Metric::Instrumentation::EmWebSocket
      alias trigger_on_message_without_d13n_instrumentation trigger_on_message
      alias trigger_on_open_without_d13n_instrumentation trigger_on_open
      alias trigger_on_close_without_d13n_instrumentation trigger_on_close
      alias send_without_d13n_instrumentation send
      
      alias trigger_on_message trigger_on_message_with_d13n_instrumentation
      alias trigger_on_open trigger_on_open_with_d13n_instrumentation
      alias trigger_on_close trigger_on_close_with_d13n_instrumentation
      alias send send_with_d13n_instrumentation
    end
  end
end

module D13n::Metric::Instrumentation
  module EmWebSocket
    include D13n::Metric::Instrumentation::WebSocketInstrumentation

    def self.included(descendance)
      descendance.extend(ClassMethods)
    end

    module ClassMethods

    end

    def trigger_on_message_with_d13n_instrumentation(*args, &block)
      options = {:category => :websocket, :name => :websocket_onmessage}
      request[:request_content_length] = args[0].size if args.is_a?(Array) 
      
      perform_websocket_with_d13n_stream(options) do
        trigger_on_message_without_d13n_instrumentation(*args, &block)
      end
    end

    def send_with_d13n_instrumentation(*args, &block)
      response_length = args[0].size if args.is_a?(Array) 
      request[:response_content_length] = response_length || 0 if request.is_a?(Hash)
      send_without_d13n_instrumentation(*args, &block)
    end

    def trigger_on_open_with_d13n_instrumentation(*args, &block)
      trigger_on_open_without_d13n_instrumentation(*args, &block)
    end

    def trigger_on_close_with_d13n_instrumentation(*args, &block)
      trigger_on_close_without_d13n_instrumentation(*args, &block)
    end
  end
end


  