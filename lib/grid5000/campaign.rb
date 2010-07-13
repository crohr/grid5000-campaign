require 'grid5000/campaign/extensions'
require 'grid5000/campaign/requirement'

module Grid5000
  # The Campaign class represents an experiment campaign to be conducted on Grid5000.
  # It takes a set of recipes as input, and will execute the following actions:
  # * try to match the requirements;
  # * upload required files to Grid5000;
  # * instantiate the selected resources;
  class Campaign
    
    attr_reader :config
    
    def initialize(recipe)
      recipe = File.expand_path(recipe)
      if File.file?(recipe) && File.readable?(recipe)
        recipe = File.read(recipe)
      else
        raise ArgumentError, 
          "The recipe file #{recipe.inspect} does not exist or is not readable."
      end
      @config = {}
    end # def initialize
    
    # Returns the root resource
    def api
      @http ||= Http.new(config)
    end
    
    def set(variable, value)
      @config[variable.to_sym] = value
    end

    def find(*args)
      Requirement.new(self, *args)
    end
  end # class Campaign
  
end # module Grid5000
