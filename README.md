## grid5000-campaign
A tool to easily launch your experiments on Grid5000.

Just a toy for now.

## Goal
The goal is to have a powerful DSL to launch experiments on Grid5000:

    set :ssh_private_key, "~/.ssh/id_rsa"
    set :ssh_public_key, "~/.ssh/id_rsa.pub"

    set :gateway, "access.rennes.grid5000.fr"

    enable :besteffort
    enable :idempotent

    set :project, "Awesome project"
    set :name, "really awesome name"

    set :max_retries, 3
    set :max_error_rate, 10/100

    set :api_uri, "https://api.grid5000.fr"
    set :api_root, "/sid/grid5000"

    find(40.nodes).
      on(:lille, :rennes, :grenoble).
      distributed(20,10,10).
      having(
        :processor.with(:clock_speed.gt 2.G),
        :network_adapters.
          with(:enabled.eq true).
          and(:rate.gt 10.G).
          and(:interface.like(/infiniband/i, /ethernet/i))
    ) do |resources|
      
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

      sync(:rennes, :lille) do # not sure if it makes sense
        execute "script", 
          :on => resources[:lille]
        execute "script", 
          :on => resources[:rennes], 
          :stdout => "~/public/stdout.{{site_uid}}.{{job_uid}}"
      end

      # global
      notify "xmpp:crohr@jabber.grid5000.fr"

    end


## Development
* Install ruby 1.9 (you may use `rvm`)
* `gem install bundler`
* `git clone git://github.com/crohr/grid5000-campaign.git`
* `cd grid5000-campaign && bundle install`

Run the tests:

* `bundle exec spec spec/`

Run the examples:

* `ruby examples/find-nodes`

## License
Not decided yet.
