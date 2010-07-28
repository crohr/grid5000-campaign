# set :ssh_public_key, "~/.ssh/id_rsa.pub"
# set :ssh_private_key, ""

set :gateway, "access.rennes.grid5000.fr"

set :besteffort, true
set :idempotent, true

set :project, "Awesome project"
set :name, "really awesome name"

set :api_uri, "https://api.grid5000.fr"
set :api_root, "/sid/grid5000"

set :max_retries, 3
set :max_error_rate, 10/100

sequential do # not required here, since sequential is the default
  rsync("local:~/my-data", "remote:~/campaign/my-data", :on => [:rennes, :grenoble])
  
  export("remote:~/campaign/my-data", :via => :http, :port => 4567, :on => [:rennes, :grenoble])
  
  parallel do
    set1 = launch(
      40.instances, 
      :environment => "lenny-x64-base", 
      :having => [
        :architecture.with(:smp_size.gt 2)
      ],
      :notify => "xmpp:crohr@jabber.grid5000.fr"
    )
    
    set2 = launch(
      20.instances, 
      :environment => :default,
      :on => [:rennes, :lille],
      :distribution => [10, 10],
      :having => [
        :processor.with(:clock_speed.gt 2.G)
      ]
    )
  end
  
  execute("hostname", :on => set1+set2)
end
