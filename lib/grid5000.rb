require 'grid5000/campaign'

require 'logger'

module Grid5000
  def self.logger=(logger)
    @logger = logger
  end
  def self.logger
    @logger ||= Logger.new(STDERR)
  end
  
end
