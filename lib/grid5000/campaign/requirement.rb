module Grid5000
  class Campaign
    class Requirement
    
      attr_reader :campaign, 
                  :properties,
                  :nodes,
                  :locations
    
      def initialize(campaign, nodes)
        @campaign = campaign
        @nodes = nodes
        @properties = {}
        @locations = []
        @distributed = :evenly
      end # def initialize
    
      def on(*args, &block)
        @locations = if args.empty?
          Grid5000.api.root.sites.map{|site| site["uid"].to_sym}
        else
          args
        end
        self_or_execute(&block)
      end
    
      def having(*args, &block)
        args.each do |symbol|
          properties[symbol] = symbol.conditions
        end
        self_or_execute(&block)
      end
    
      def distributed(*args, &block)
        if locations.empty?
          raise ArgumentError, "You must specify at least one location first."
        else
          if args.empty?
            @distributed = :evenly
          elsif args.length == 1
            @distributed = args.shift.to_sym
          elsif args.length > locations.length
            raise ArgumentError, "Your distribution exceeds the number of locations."
          else
            @distributed = args
          end
          self_or_execute(&block)
        end
      end
    
      def distribution
        if @distributed == :evenly
          partition = nodes/locations.length
          distribution = locations.map{ partition }
          distribution.last += nodes-(partition*locations.length)
        else
          distribution = @distributed
        end
        distribution
      end
    
      # Attempts to find a match between the requirements 
      # and the available nodes
      def match
        compute_status_conditions
        matching_nodes = []
        campaign.api.root.get(:sites).each do |site|
          site.get(:clusters).each do |cluster|
            cluster.get(:nodes).each do |node|
              properties.each do |property, conditions|
                node["status"] = site.get(:status)["items"].find{ |status|
                  status["node_uid"] == node["uid"]
                }
                if conditions.all?{ |condition|
                  condition.call(node[property.to_s])
                }
                  matching_nodes << node
                end
              end
            end
          end
        end
        matching_nodes
      end
    
      protected
      def self_or_execute(&block)
        if block
          match && block.call(_)
        else
          self
        end
      end
    
      def compute_status_conditions
        @properties[:status] ||= []
        if campaign.config[:besteffort]
          @properties[:status] << Proc.new { |status|
            status["system_state"] == "free"
          }
        else
          @properties[:status] << Proc.new { |status|
            ["free", "besteffort"].include?(status["system_state"])
          }
        end
        # we can also add conditions on reservations for campaigns in the future
      end
    
    
      def match?(node)
      
      end
    
    end # class Requirement
    
  end # class Campaign
end # module Grid5000