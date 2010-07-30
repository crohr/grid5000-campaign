
%w{base wait launch execute}.each do |klass|
  require "grid5000/campaign/operation/#{klass}"
end

module Grid5000
  class Campaign
    module Operation
      
    end # module Operation
    
  end # class Campaign
end # module Grid5000

