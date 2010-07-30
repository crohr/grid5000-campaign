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
      @running = false
      block.call(self) if block
    end
    
    # Run the campaign
    def run!
      @running = true
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
        @running = false
        self
      end
    end # def run!

    def sequential(&block)
      @mode = :sequential
      block.call#(self)
      self
    end # def sequential
    
    def parallel(&block)
      @mode = :parallel
      @operations << []
      block.call#(self)
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
    
    def wait(seconds = nil, options = {}, &block)
      options[:wait] ||= seconds
      add_operation Operation::Wait.new(self, &block)
    end # def wait
    
    def [](id)
      if !running?
        proxy = Proc.new{
          @registry[id.to_sym]
        }
        class << proxy
          attr_accessor :campaign, :stacked_methods
          def method_missing(method, *args)
            p [:method_missing, method, args]
            stacked_methods ||= []
            stacked_methods.push([method, args])
            if campaign.running?
              result = call
              while !stacked_methods.empty? do
                m, arguments = stacked_methods.shift
                result.send(method, *arguments)
              end
              stacked_methods
              result
            end
          end
        end
        proxy.campaign = self
        p proxy
        proxy
      else
        @registry[id.to_sym]
      end
    end # def []
    
    def []=(id, operation)
      @registry[id.to_sym] = operation
    end # def []=
    
    def api      
      @http ||= Http.new(
        :base_uri => config[:api_base_uri], 
        :root_uri => config[:api_root_uri],
        :username => config[:api_username],
        :password => config[:api_password],
        :logger   => config[:logger]
      )
    end # def api
    
    def running?
      @running == true
    end # def running?
    
    protected
    def add_operation(operation)
      logger.info "Planning #{mode.to_s} execution of #{operation.to_s}..."
      case mode
      when :parallel
        @operations.last << operation
      else
        @operations << operation
      end
      # register the operation
      self[operation.id] = operation
      operation
    end # def add_operation
    
  end # class Campaign
  
end # module Grid5000
