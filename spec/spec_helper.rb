require 'pp'
require 'yaml'

LIB_DIR = File.expand_path(File.dirname(__FILE__)+"/../lib")
FIX_DIR = File.expand_path("fixtures", File.dirname(__FILE__))

$LOAD_PATH.unshift LIB_DIR unless $LOAD_PATH.include?(LIB_DIR)

require 'grid5000'
require 'http'
require 'webmock/rspec'

Grid5000.logger = Logger.new(STDERR)
Grid5000.logger.level = Logger.const_get(ENV['DEBUG'] || 'DEBUG')

include Grid5000

# require File.expand_path("helpers/stub_server", File.dirname(__FILE__))

Spec::Runner.configure do |config|
  config.include WebMock
  
  config.prepend_before do
  end
  config.append_after do
  end
end

def fixture(filename)
  File.expand_path(filename, FIX_DIR)
end
