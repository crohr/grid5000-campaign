require 'pp'

LIB_DIR = File.expand_path(File.dirname(__FILE__)+"/../lib")
FIX_DIR = File.expand_path("fixtures", File.dirname(__FILE__))

$LOAD_PATH.unshift LIB_DIR unless $LOAD_PATH.include?(LIB_DIR)

require 'grid5000'
require 'http'

Grid5000.logger = Logger.new(STDERR)
Grid5000.logger.level = Logger.const_get(ENV['DEBUG'] || 'DEBUG')

include Grid5000

# Sinatra::Application.set :logger, Logger.new(STDOUT)
# Sinatra::Application.set :root, File.join(root_dir, "..")

Spec::Runner.configure do |config|
  config.prepend_before do
  end
  config.append_after do
  end
end

def fixture(filename)
  File.expand_path(filename, FIX_DIR)
end