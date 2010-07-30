module Grid5000
  class Campaign
    module Operation
      # Base class for all operations occurring in a Grid5000::Campaign.
      class Base
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
          @id ||= (config[:id] || self.hash.to_s[0...7])
        end # def id
        
        def grid(options = {})
          @grid ||= campaign.api.root.load(
            :depth => 3, 
            :only => [:sites, :clusters, :nodes]
          )
        end # def grid
        
      end # class Base
    end # module Operation
  end # class Campaign
end # module Grid5000
