# set :ssh_public_key, "~/.ssh/id_rsa.pub"
# set :ssh_private_key, ""

set :gateway, "access.rennes.grid5000.fr"

set :besteffort, true
set :idempotent, true

set :project, "Awesome project"
set :name, "really awesome name"

set :max_retries, 3
set :error, 10/100

set :api_uri, "https://api.grid5000.fr"
set :api_version, "sid"

# find
# deploy
# execute
# notify
# kill

find(40.nodes).
  on(:lille, :rennes, :grenoble).
  distributed(4,5,10).
  having(
    :processor.with(:clock_speed.gt(2.G)),
    :network_adapters.with(:enabled.eq(true)).
      and(:rate.gt(10.G)).and(:interface.like(/infiniband/i, /ethernet/i))
  ) do |resources|
  # this will attempt to submit the jobs on each site
  # ^ this is done locally

  # v this is done remotely
  # this generates a ruby script that will be uploaded somewhere (use SSH gateway), and passed as the script to execute on job launch (deployment, script execution)
  # it will replace resources[] by the real list of resources, 
  
  # the following is executed by a script on the frontend
  
  master = resources[:rennes].shift
  
  # lille
  deploy "http://public.rennes.grid5000.fr/~crohr/images/lenny-x64-base", 
    :version => 1, 
    :on => resources[:lille]
  
  # rennes
  deploy "lenny-x64-nfs", 
    :on => master
  deploy "lenny-x64-base", 
    :version => 1, 
    :on => resources[:rennes]
  execute "master-script", 
    :on => master
    
  sync(:rennes, :lille) do  
    execute "script", 
      :on => resources[:lille] # use taktuk ?
    execute "script", 
      :on => resources[:rennes], 
      :stdout => "~/public/stdout.$OAR_ID"
  end
  
  
  # global
  notify "xmpp:crohr@jabber.grid5000.fr", "mailto:cyril.rohr@irisa.fr"
  
  
end


