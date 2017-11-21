require 'spec_helper'


describe D13n::Logger::SilenceLogger do
  subject {described_class.new}
  context 'all instance logger methods' do
    it {is_expected.to respond_to :fatal}
    it {is_expected.to respond_to :error}
    it {is_expected.to respond_to :warn}
    it {is_expected.to respond_to :info}
    it {is_expected.to respond_to :debug}
  end
end

describe D13n::Logger do
  context "stdout logger" do
    context '#initialize' do
      before(:each) do
        allow_any_instance_of(D13n::Logger).to receive(:warn)
        allow_any_instance_of(D13n::Logger).to receive(:create_logger)
        allow_any_instance_of(D13n::Logger).to receive(:set_log_level!)
        allow_any_instance_of(D13n::Logger).to receive(:set_log_format!)
        allow_any_instance_of(D13n::Logger).to receive(:gather_startup_logs)
      end

      it "has instance root variable" do
        @logger = D13n::Logger.new()
        expect(@logger.instance_variable_get(:@root)).to be_eql("STDOUT") 
      end

      it "can create logger" do
        @logger = D13n::Logger.new()
        expect(@logger).to have_received(:create_logger)
      end

      it "can set logger level" do
        @logger = D13n::Logger.new()
        expect(@logger).to have_received(:set_log_level!)
      end

      it "can set log format" do
        @logger = D13n::Logger.new()
        expect(@logger).to have_received(:set_log_format!)
      end
    end
  end

  context '#create_logger' do
    let(:override_logger) {double()}
    before(:each) {
      allow_any_instance_of(D13n::Logger).to receive(:warn)
      @logger = D13n::Logger.new()
    }

    context 'when specify override logger' do
      it 'can override log' do
        @logger.send(:create_logger,"",override_logger)
        expect(@logger.instance_variable_get(:@log)).to be_eql override_logger
      end
    end

    context 'when no specify override_logger' do
      it 'can set silence by config log_level' do
        allow(::D13n.config).to receive(:[]).with(:log_level).and_return(:silence)
        @logger.send(:create_logger,"",nil)
        expect(@logger.instance_variable_get(:@log)).to be_instance_of D13n::Logger::SilenceLogger
      end

      it 'can log to stdout when config log_file_path is STDOUT' do
        allow(::D13n.config).to receive(:[])
        allow(::D13n.config).to receive(:[]).with(:log_file_path).and_return("STDOUT")
        @logger.send(:create_logger,"",nil)
        expect(@logger.instance_variable_get(:@log).instance_variable_get(:@logdev).dev).to be_eql STDOUT 
      end

      context 'when file path not found' do
        before(:each) {
          allow_any_instance_of(D13n::Logger).to receive(:warn)
          allow(@logger).to receive(:find_or_create_file_path).and_return(nil)
          @logger.send(:create_log_to_file,"root")
        }

        it 'can log to STDOUT' do
          expect(@logger.instance_variable_get(:@log).instance_variable_get(:@logdev).dev).to be_eql STDOUT
        end

        it 'can warn error to create log directory' do
          expect(@logger).to have_received(:warn)
        end
      end

      context 'when log file /fake/path/axle.log found or created' do
        before(:each) {
          allow(@logger).to receive(:find_or_create_file_path).and_return('/fake/path')
          allow(::Logger).to receive(:new)
          @logger.send(:create_log_to_file,"root")
        }
        it 'can create a log file' do
          expect(::Logger).to have_received(:new).with('/fake/path/axle.log')
        end
      end

      context 'when log file /fake/path/axle.log not found or created' do
        before(:each) {
          allow(@logger).to receive(:find_or_create_file_path).and_return('/fake/path')
          @logger.send(:create_log_to_file,"root")
        }

        it 'can rescue logger exception' do
          expect{@logger.send(:create_log_to_file,"root")}.to_not raise_error
        end

        it 'can log to STDOUT' do
          expect(@logger.instance_variable_get(:@log).instance_variable_get(:@logdev).dev).to be_eql STDOUT
        end

        it 'can warn error to create log file' do
          expect(@logger).to have_received(:warn)
        end
      end
    end
  end

  context '::log_level_for' do
    context 'when invalid level' do
      it 'can fetch default INFO level' do
        expect(described_class.log_level_for('dummy')).to be_eql ::Logger::INFO
      end
    end

    context 'when valid level' do
      it 'can fetch DEBUG level by string "debug"' do
        expect(described_class.log_level_for("debug")).to be_eql ::Logger::DEBUG
      end

      it 'can fetch INFO level by string "info"' do
        expect(described_class.log_level_for("info")).to be_eql ::Logger::INFO
      end

      it 'can fetch WARN level by string "warn"' do
        expect(described_class.log_level_for("warn")).to be_eql ::Logger::WARN
      end

      it 'can fetch ERROR level by string "error"' do
        expect(described_class.log_level_for("error")).to be_eql ::Logger::ERROR
      end

      it 'can fetch FATAL level by string "fatal"' do
        expect(described_class.log_level_for("fatal")).to be_eql ::Logger::FATAL
      end
    end
  end

  context '#set_log_level!' do
    before(:each) {
      allow_any_instance_of(D13n::Logger).to receive(:warn)
      @logger = D13n::Logger.new()
    }
    context 'when invalid level' do
      it 'can set default INFO level' do
        @logger.send(:set_log_level!)
        expect(@logger.instance_variable_get(:@log).level).to be_eql ::Logger::INFO
      end
    end

    context 'when valid level' do
      it 'can set INFO level' do
        allow(D13n.config).to receive(:[]).with(:log_level).and_return('info')
        @logger.send(:set_log_level!)
        expect(@logger.instance_variable_get(:@log).level).to be_eql ::Logger::INFO
      end
      it 'can set DEBUG level' do
        allow(D13n.config).to receive(:[]).with(:log_level).and_return('debug')
        @logger.send(:set_log_level!)
        expect(@logger.instance_variable_get(:@log).level).to be_eql ::Logger::DEBUG
      end
      it 'can set WARN level' do
        allow(D13n.config).to receive(:[]).with(:log_level).and_return('warn')
        @logger.send(:set_log_level!)
        expect(@logger.instance_variable_get(:@log).level).to be_eql ::Logger::WARN
      end
      it 'can set ERROR level' do
        allow(D13n.config).to receive(:[]).with(:log_level).and_return('error')
        @logger.send(:set_log_level!)
        expect(@logger.instance_variable_get(:@log).level).to be_eql ::Logger::ERROR
      end
      it 'can set FATAL level' do
        allow(D13n.config).to receive(:[]).with(:log_level).and_return('fatal')
        @logger.send(:set_log_level!)
        expect(@logger.instance_variable_get(:@log).level).to be_eql ::Logger::FATAL
      end
    end
  end

  context '#set_log_format!' do
    before(:each) {
      @logger = D13n::Logger.new()
    }

    context 'when log STDOUT' do
      before(:each) {
        allow(@logger).to receive(:log_stdout?).and_return(true)
      }
      it 'log with prefix "** [Axle]"' do
        allow(D13n.config).to receive(:app_name).and_return("Axle")
        @logger.send(:set_log_format!)
        expect(@logger.instance_variable_get(:@prefix)).to be_eql('** [Axle]')
      end
    end

    context 'when log to file' do
      before(:each) {
        allow(@logger).to receive(:log_stdout?).and_return(false)
      }
      
      it 'log without prefix' do
        @logger.send(:set_log_format!)
        expect(@logger.instance_variable_get(:@prefix)).to be_empty
      end
    end

    describe 'fomatter' do
      before(:each) {
        allow(@logger).to receive(:log_stdout?).and_return(true)
        allow(D13n.config).to receive(:app_name).and_return("Axle")
        allow(@logger).to receive(:request_id).and_return('request')
      }

      let(:ts) {Time.now}
      let(:severity) {"INFO"}
      let(:st_msg) {"This is a message"}
      let(:hs_msg) {{key: "value"}}

      context 'when log_fomat is json' do
        before(:each) {
          allow(@logger).to receive(:log_format).and_return('json')
          allow(@logger).to receive(:tag_hash).and_return({})
        }

        it 'can return message with string type' do
          @logger.send(:set_log_format!)
          log_data = {app: "Axle", 
                       ts: ts.strftime("%F %H:%M:%S %z"),
                       pid: $$,
                       severity: severity,
                       request_id: 'request',
                       message: st_msg
                     }
          expect(@logger.formatter.call(severity,ts, 'axle', st_msg)).to be_eql("#{log_data.to_json}\n")
        end

        it 'can return message with string type' do
          @logger.send(:set_log_format!)
          log_data = {app: "Axle", 
                       ts: ts.strftime("%F %H:%M:%S %z"),
                       pid: $$,
                       severity: severity,
                       request_id: 'request'
                     }.merge! hs_msg
          expect(@logger.formatter.call(severity,ts, 'axle', hs_msg)).to be_eql("#{log_data.to_json}\n")
        end
      end

      context 'when log_format is not json' do
        before(:each) {
          allow(@logger).to receive(:log_format).and_return('string')
        }

        it 'can return log string' do
          @logger.send(:set_log_format!)
          log_data = "** [Axle][#{ts.strftime("%F %H:%M:%S %z")} (#{$$})] #{severity} request : #{st_msg}\n"
          expect(@logger.formatter.call(severity,ts, 'axle', st_msg)).to be_eql(log_data)
        end
      end
    end
  end
end