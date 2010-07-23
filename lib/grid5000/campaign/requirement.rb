require 'set'

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
          Grid5000.api.root.sites.map{|site| site["uid"]}
        else
          args.map{|symbol_or_string| symbol_or_string.to_s}
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
    
      # Returns the required number of nodes on each location
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
        matching_nodes = []
        p campaign.api.config
        sites = campaign.api.root.get(:sites)
        valid_sites = sites.select{ |site|
          locations.include?(site["uid"])
        }
        if valid_sites.empty?
          raise MatchingError, "At least one location requirement cannot be satisfied (#{locations.inspect})."
        else
          compute_status_conditions
          distribution_by_site = Hash[locations.zip(distribution)]
          sites.pget(:status) do |site, status|
            site['status'] = status
          end
          sites.pget(:clusters) do |site, clusters|
            next unless distribution_by_site.has_key?(site["uid"])
            clusters.pget(:nodes) do |cluster, nodes|
              nodes.each do |node|
                node["status"] = site['status']["items"].find{ |status|
                  status["node_uid"] == node["uid"]
                }
                node["cluster_uid"] = cluster["uid"]
                node["site_uid"] = site["uid"]
                if distribution_by_site[site["uid"]] > 0 && match?(node.properties)
                  distribution_by_site[site["uid"]] -= 1
                  matching_nodes << node
                end
                break if distribution_by_site[site["uid"]] <= 0
              end
            end
          end
          matching_nodes
        end

      end
      
      
      # Returns true if the 
      def match?(hash)
        properties.all? do |(property, conditions)|
          passed = conditions.all?{ |condition|
            condition.call(hash)
          }
          if passed
            true
          else
            Grid5000.logger.debug "Cannot find a match on #{property.inspect} for #{hash["uid"]}"
            false
          end
        end
      end
    
      protected
      def self_or_execute(&block)
        if block
          block.call(match)
        else
          self
        end
      end
    
      # Adds new conditions on node status, 
      # according to options set in the campaign
      def compute_status_conditions
        @properties[:status] ||= []
        if campaign.config[:besteffort]
          @properties[:status] << Proc.new { |hash|
            hash["status"]["system_state"] == "free"
          }
        else
          @properties[:status] << Proc.new { |hash|
            ["free", "besteffort"].include?(hash["status"]["system_state"])
          }
        end
        # we can also add conditions on reservations for campaigns in the future
      end    
    
    end # class Requirement
    
  end # class Campaign
end # module Grid5000