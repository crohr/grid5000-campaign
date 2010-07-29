require 'http'
require 'grid5000/campaign/extensions'
require 'grid5000/campaign/operation'

module Grid5000
  class Campaign
    
    class Error < StandardError; end
    class InvalidOperation < Error; end
    class DeploymentError < Error; end
    class JobError < Error; end
    
    attr_reader :config, :mode, :registry
    attr_accessor :logger
    
    
    def initialize(config = {}, &block)
      @config = config.symbolize_keys
      @logger = @config[:logger] || Logger.new(STDERR)
      @mode = :sequential
      @operations = []
      @registry = {}
      block.call(self) if block
    end
    
    # Run the campaign
    def run!
      EM.synchrony do
        @operations.each do |operation|
          case operation
          # parallel operations
          when Array
            # TODO: make it parallel !
            operation.each do |op|
              op.execute!
            end
          else
            op.execute!
          end
        end
        EM.stop
        self
      end
    end # def run!

    def sequential(&block)
      @mode = :sequential
      block.call(self)
      self
    end # def sequential
    
    def parallel(&block)
      @mode = :parallel
      @operations << []
      block.call(self)
      @mode = :sequential
      self
    end # def parallel
    
    def rsync(source, target, options = {})
      options[:source] ||= source
      options[:target] ||= target
      add_operation Operation::Rsync.new(self, options)
    end
    
    def export(source, options = {})
      options[:source] ||= source
      add_operation Operation::Export.new(self, options)
    end # def export
    
    def launch(count, options = {})
      options[:count] ||= count
      add_operation Operation::Launch.new(self, options)
    end # def launch
    
    def execute(command, options = {})
      options[:command] ||= command
      add_operation Operation::Execute.new(self, options)
    end # def execute
    
    def wait(seconds, &block)
      options[:wait] ||= seconds
      add_operation Operation::Wait.new(self, &block)
    end # def wait
    
    def add_operation(operation)
      logger.info "Planning #{mode.to_s} execution of #{operation.to_s}..."
      case mode
      when :parallel
        @operations.last << operation
      else
        @operations << operation
      end
      operation
    end # def add_operation
    
    def [](id)
      @registry[id.to_sym]
    end
    
    def []=(id, operation)
      @registry[id.to_sym] = operation
    end
    
    def api      
      @http ||= Http.new(
        :base_uri => config[:api_base_uri], 
        :root_uri => config[:api_root_uri],
        :username => config[:api_username],
        :password => config[:api_password],
        :logger   => config[:logger]
      )
    end # def api
    
  end # class Campaign
  
end # module Grid5000
