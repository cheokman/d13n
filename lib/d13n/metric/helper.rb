module D13n::Metric
  module Helper
    def self.http_request_for(app_name, direction)
      downcase_direction = direction.to_s_downcase
      check_direction(downcase_direction)
      scope ||= []
      scope << D13n.idc_name
      scope << D13n.app_name.downcase
      scope << D13n.idc_env
      scope << http
      scope << downcase_direction
      scope
    end

    def self.http_request_count_for(service, direction)
      scope = http_request_for(service, direction)
      scope << "count"
      scope.join('.')
    end

    def self.http_request_timing_for(service, direction)
      scope = http_request_for(service, direction)
      scope << "timing"
      scope.join('.')
    end

    def self.http_in_tracable?
      D13n.config[:'metric.app.http.in.tracable'] == 'true' || D13n.config[:'metric.app.http.in.tracable'] == true
    end

    def self.http_out_tracable?
      D13n.config[:'metric.app.http.out.tracable'] == 'true' || D13n.config[:'metric.app.http.out.tracable'] == true
    end

    def self.db_tracable?
      D13n.config[:'metric.app.db.tracable'] == 'true' || D13n.config[:'metric.app.db.tracable'] == true
    end

    def self.biz_tracable?
      D13n.config[:'metric.business.state.tracable'] == 'true' || D13n.config[:'metric.business.state.tracable'] == true
    end

    def self.exception_tracable?
      D13n.config[:'metric.app.state.exception.tracable'] == 'true' || D13n.config[:'metric.app.state.exception.tracable'] == true
    end

    def self.service_for(uri)
      port = (uri.port.to_i == 80 ? "" : ":#{uri.port}")
      url = "#{uri.scheme}://#{uri.host}#{port}"
      expected_service = D13n.config.alias_key_for(url)
      return nil if expected_service.nil?
      expected_service.to_s.downcase
    end

    def self.endpoint_for(uri)
      path = uri.path
      expected_path = D13n.config.alias_key_for(path)
      return nil if expected_path.nil?
      expected_path.to_s.downcase
    end
  end
end