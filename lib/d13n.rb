require 'd13n/version'
require 'logger'
module D13n
  def self.logger
    @logger = ::Logger.new(STDOUT)
  end

  def self.logger=(logger)
  end
end