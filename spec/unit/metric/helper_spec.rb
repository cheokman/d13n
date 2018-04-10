require 'spec_helper'
require 'd13n/metric/helper'

describe D13n::Metric::Helper do
  context 'http_request_for' do
    before :each do
      allow(D13n).to receive(:idc_name).and_return('hqidc')
      allow(D13n).to receive(:app_name).and_return('d13n')
      allow(D13n).to receive(:idc_env).and_return('stg')
      allow(described_class).to receive(:check_direction)
    end

    it 'should return scope informatin in array' do
      expect(described_class.http_request_for('d13n', :IN)).to be_eql([
        'hqidc',
        'd13n',
        'stg',
        'http',
        'in'
      ])
    end
  end

  context 'http_request_count_for' do
    before :each do
      allow(described_class).to receive(:http_request_for).and_return([
        'hqidc',
        'd13n',
        'stg',
        'http',
        'in'
      ])
    end

    it 'should return dotted scope string' do
      expect(described_class.http_request_count_for('d13n', :IN)).to be_eql('hqidc.d13n.stg.http.in.count')
    end
  end

  context 'http_request_timing_for' do
    before :each do
      allow(described_class).to receive(:http_request_for).and_return([
        'hqidc',
        'd13n',
        'stg',
        'http',
        'in'
      ])
    end

    it 'should return dotted scope string' do
      expect(described_class.http_request_timing_for('d13n', :IN)).to be_eql('hqidc.d13n.stg.http.in.timing')
    end
  end

  {
    'http_in_tracable?' => 'metric.app.http.in.tracable',
    'http_out_tracable?' => 'metric.app.http.out.tracable',
    'db_tracable?' => 'metric.app.db.tracable',
    'biz_tracable?' => 'metric.business.state.tracable',
    'exception_tracable?' => 'metric.app.state.exception.tracable'
  }.each do |k, v| 
    context "#{k}" do
      context 'when false boolean' do
        before :each do
          allow(D13n.config).to receive(:[]).with(v.to_sym).and_return(false)
        end

        it "should call #{k} return false" do
          expect(described_class.send(k.to_sym)).to be_falsy
        end
      end

      context 'when false string' do
        before :each do
          allow(D13n.config).to receive(:[]).with(v.to_sym).and_return('false')
        end

        it "should call #{k} return false" do
          expect(described_class.send(k.to_sym)).to be_falsy
        end
      end

      context 'when true boolean' do
        before :each do
          allow(D13n.config).to receive(:[]).with(v.to_sym).and_return(true)
        end

        it "should call #{k} return true" do
          expect(described_class.send(k.to_sym)).to be_truthy
        end
      end

      context 'when true string' do
        before :each do
          allow(D13n.config).to receive(:[]).with(v.to_sym).and_return('true')
        end

        it "should call #{k} return true" do
          expect(described_class.send(k.to_sym)).to be_truthy
        end
      end
    end
  end

  context 'service_for' do
    before :each do
      allow(D13n.config).to receive(:alias_key_for).with('http://my.service:8080').and_return('my')
      allow(D13n.config).to receive(:alias_key_for).with('http://myfake.service').and_return(nil)
      @my_service = URI("http://my.service:8080")
      @myfake_service = URI('http://myfake.service')
    end

    it 'should return alias for my.service' do
      expect(described_class.service_for(@my_service)).to be_eql('my')
    end

    it 'should return nil for myfake.service' do
      expect(described_class.service_for(@myfake_service)).to be_nil
    end
  end

  context 'endpoint_for' do
    before :each do
      allow(D13n.config).to receive(:alias_key_for).with('/bet').and_return('bet')
      allow(D13n.config).to receive(:alias_key_for).with('/look').and_return(nil)
      @my_service = URI("http://my.service:8080/bet")
      @myfake_service = URI('http://myfake.service/look')
    end

    it 'should return alias for my service' do
      expect(described_class.endpoint_for(@my_service)).to be_eql('bet')
    end
    

    it 'should return nil for myfake service' do
      expect(described_class.endpoint_for(@myfake_service)).to be_nil
    end
  end
end