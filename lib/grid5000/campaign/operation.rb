%w{wait launch}.each do |klass|
  require "grid5000/campaign/operation/#{klass}"
end

module Grid5000
  class Campaign
    
    # Base class for all operations occurring in a Grid5000::Campaign.
    class Operation
      attr_reader :config, :campaign
  
      def initialize(campaign, config = {})
        @campaign = campaign
        @config = config.symbolize_keys
        raise InvalidOperation unless self.valid?
      end # def initialize
  
      def valid?
        validate
      end # def valid?
  
      #  Should be overwritten by descendant classes
      def validate
        true
      end # def validate
  
      # Returns the specified unique ID of the operation,
      # or a generated one.
      def id
        @id ||= (config[:id] || self.hash[0...7])
      end # def id
  
      class << self
        def grid(options = {})
          @grid ||= campaign.api.root.load(
            :depth => 3, 
            :only => [:sites, :clusters, :nodes]
          )
        end
      end # class << self
    end # class Operation
    
  end # class Campaign
end # module Grid5000
