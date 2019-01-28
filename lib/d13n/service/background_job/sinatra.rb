module Sinatra
  class Base
    class << self
      alias_method :run_without_callback, :run!

      def background_job(opts = {}, &block)
        @background_jobs ||= []
        @background_jobs << {opts: opts, blk: block}
      end

      def background_job_run!
        return if @background_jobs.nil?
        @background_jobs.each do |j|
          j[:blk].call(j[:opts])
        end
      end

      def run!(*args, &block)
        background_job_run!
        run_without_callback(*args, &block)
      end
    end
  end
end