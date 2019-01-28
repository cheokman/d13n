module Sinatra
  class Base
    class << self
      alias_method :run_without_callback, :run!

      def background_job(opts = {}, &block)
        @background_jobs ||= []
        @background_jobs << {opts: opts, blk: block}
      end

      def background_job_run!
        @background_jobs.each do |j|
          j[:blk].call(j[:opts])
        end
      end

      def run!(options = {}, &block)
        background_job_run!
        run_without_callback(options, block)
      end
    end
  end
end