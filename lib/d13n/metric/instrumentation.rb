require 'd13n/metric/conductor'
module D13n::Metric::Instrumentation
  def load_instrumentation_files path
    Dir.glob(path) do |file|
      begin
        require file.to_s
      rescue => e
        D13n.logger.warn "Error loading instrumentation file '#{file}':", e
      end
    end 
  end

  def add_instrumentation file
    if @instrumented
      load_instrumentation_files file
    else
      @instrumentation_files << file
    end
  end

  def setup_instrumentation
    _setup_instrumentation
  end

private
  def _setup_instrumentation
    return if @instrumented

    @instrumentation_files = []

    @instrumented = true

    instrumentation_path = File.expand_path(File.join(File.dirname(__FILE__), 'instrumentation'))

    @instrumentation_files << File.join(instrumentation_path, '*.rb')

    @instrumentation_files.each { |path| load_instrumentation_files(path) }
    Conductor.perform!
    D13n.logger.info "Finished instrumentation"
  end
end