module Grid5000
  class Campaign
    module Operation
      class Execute < Base

        def initialize(*args)
          super(*args)
        end # def initialize

        def execute!
          campaign.logger.info "Executing #{config[:command].inspect}..."
          true
        end # def execute!

      end # class Execute
    end # module Operation
  end # class Campaign
end # module Grid5000
