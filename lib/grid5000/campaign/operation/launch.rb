module Grid5000
  class Campaign
    
    # Represents a launch of instances, 
    # possibly with non-default environment to be deployed.
    # It deals with:
    # * selecting the clusters that match the user's requirements, 
    # * launch the corresponding jobs on the specified locations, and
    # * (possibly) deploy the requested environment on the nodes.
    class Launch < Operation
      attr_reader :jobs, :deployments

      def initialize(*args)
        super(*args)
        @deployments = []
        @jobs = []
        @nodes = []
      end


      # Execute the operation
      def execute!
        reserve!(find_matching_nodes)

        Wait.new(campaign, :seconds => 2.minutes) {
          jobs.all?{|j| campaign[j.id].running?}
        }.execute!

        if deploy?
          deploy!(jobs)
          Wait.new(campaign, :seconds => 15.minutes) {
            deployments.all?{|d| campaign[d.id].terminated?}
          }
        end

        # Register the launch in the campaign
        campaign[id] = self
        self
      end # def execute!


      # Find nodes matching the requirements
      # Returns an array of nodes objects
      def find_matching_nodes
        matching_nodes_by_site = {}
        req = requirements
        self.class.grid.sites.pget(:status) do |site, status|
          matching_nodes = []
          site.clusters.each do |cluster|
            cluster.nodes.each do |node|
              next if matching_nodes.length >= distribution[site["uid"]]
              node["status"] = status.find{|s| s["node_uid"] == node["uid"]}
              node["cluster_uid"] = cluster["uid"]
              node["site_uid"] = site["uid"]
              matching_nodes << node if req.all?{ |property|
                property.conditions.all?{ |condition|
                  condition.call(node[property.to_s])
                }
              }
            end
          end
          matching_nodes_by_site[site["uid"]] = matching_nodes
        end
        campaign.logger.info "Found the required number of instances."
        matching_nodes_by_site
      end # def find_matching_nodes


      # Try to launch the required number of jobs 
      # to satisfy the number of instances needed
      def reserve!(nodes_by_site)
        site_uris = {}
        campaign.logger.info "Launching jobs..."
        multi = EM::Synchrony::Multi.new
        self.class.grid.sites.each do |site|
          next unless nodes_by_site.has_key?(site["uid"])
          site_uris[site["uid"]] = site.uri_to(:self).to_s
          params = {
            :project      => campaign.config[:project],
            :name         => campaign.config[:name],
            :resources    => "nodes=#{distribution[site["uid"]]},walltime=#{walltime}",
            :properties   => nodes_by_site[site["uid"]].map{|node|
              "-p cluster = '#{node["cluster_uid"]}'"
            }.uniq.join(" ")
          }
          uri = site.uri_to(:jobs).to_s
          campaign.logger.debug "POSTing job to #{uri} with params=#{params.inspect}..."
          multi.add(
            site["uid"], 
            EM::HttpRequest.new(uri).apost(:body => params)
          )
        end
        # Attribute ID to each job, and register them in campaign.
        result = multi.perform
        success = result.responses[:callback].length
        campaign.logger.info "#{success}/#{nodes_by_site.length} jobs successfully launched."
        if success < nodes_by_site.length
          raise JobError, "Unable to launch one of the jobs."
        else
          result.responses[:callback].each do |site_uid, response|
            response = Http.handle_response(response, site_uris[site_uid])
            jobs << response
          end
          jobs
        end
      end # def reserve!

      # Launch deployments on all the nodes of each job
      def deploy!(jobs)
        site_uris = {}
        nodes_by_site = {}
        jobs.each do |job|
          site_uris[job["site_uid"]] = job.uri_to(:parent).to_s
          nodes_by_site[job["site_uid"]] ||= []
          nodes_by_site[job["site_uid"]] << *job["assigned_nodes"]
        end

        campaign.logger.info "Launching deployments..."
        multi = EM::Synchrony::Multi.new
        self.class.grid.sites.each do |site|
          next unless nodes_by_site.has_key?(site["uid"])
          params = {
            :nodes => nodes_by_site[site["uid"]],
            :environment => config[:environment],
            :key => config[:key] || campaign.config[:ssh_public_key],
            :notifications => config[:notifications] || campaign.config[:notifications] || []
          }
          uri = site.uri_to(:deployments).to_s
          campaign.logger.debug "POSTing deployment to #{uri} with params=#{params.inspect}..."
          multi.add(
            site["uid"], 
            EM::HttpRequest.new(uri).apost(:body => params)
          )
        end
        result = multi.perform
        success = result.responses[:callback].length
        campaign.logger.info "#{success}/#{jobs.length} deployments successfully launched."
        if success < jobs.length
          raise DeploymentError, "Unable to launch one of the deployments."
        else
          result.responses[:callback].each do |site_uid, response|
            response = Http.handle_response(response, site_uris[site_uid])
            deployments << response
          end
          deployments
        end
      end # def deploy!


      # ===========
      # = Helpers =
      # ===========

      # Returns a hash of {site_uid => number_of_instances}
      def distribution
        config[:distribution] ||= :even
        if config[:distribution] == :even
          partition = config[:count]/locations.length
          dist = locations.map{ partition }
          dist[-1] += config[:count]%partition
        else
          dist = config[:distribution]
        end
        Hash[locations.zip(dist)]
      end

      # Returns an array of site UIDs
      def locations
        config[:on] ||= self.class.grid.sites.map{|site|
          site["uid"]
        }
        # Ensure we only get an Array of Strings and no Symbols
        config[:on] = [config[:on]].flatten.map(&:to_s)
      end

      # Returns the walltime of the launch
      def walltime
        config[:for] ||= 1.hour
        hours = config[:for].to_i/3600
        minutes = (config[:for]-(hours*3600)).to_i/60
        seconds = config[:for]-hours*3600-minutes*60
        "#{hours}:#{minutes}:#{seconds}"
      end # def walltime

      # Is a deployment necessary ?
      def deploy?
        config[:environment] && config[:environment] != :default
      end

      # Returns an array of nodes FQDN.
      # If a deployment has been executed on the node and 
      # has failed, the node is discarded.
      def instances
        jobs.map{|job|
          job["assigned_nodes"].select{|fqdn|
            if deploy? 
              deployments.find{|deployment|
                deployment["result"] && 
                deployment["result"][fqdn] &&
                deployment["result"][fqdn]["state"] == "OK"
              }
            else
              true
            end
          }
        }.flatten
      end

      # Returns an array of condition procs on symbols
      def requirements
        req = config[:having] || []
        req.unshift(:site_uid.in(locations))
        req.unshift(:supported_job_types.
          with(:deploy.eq true)
        ) if deploy?
        req.unshift(:status.
          with(:hardware_state.eq('alive')).
          # TODO: include or do not include besteffort based n user prefs
          and(:system_state).in('besteffort', 'free'))
        req
      end # def requirements

    end # class Launch
  end # class Campaign
end # module Grid5000