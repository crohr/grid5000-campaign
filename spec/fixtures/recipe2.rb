require "logger"
require "grid5000/campaign"

logger = Logger.new(STDERR)
logger.level = Logger::DEBUG

Grid5000::Campaign.new({
  :gateway         => "access.bordeaux.grid5000",
  :project         => "Revolutionary Project",
  :name            => "Take #1",
  :api_base_uri    => "https://api.grid5000.fr",
  :api_root_uri    => "/sid/grid5000",
  :ssh_public_key  => "~/.ssh/id_rsa.pub",
  :ssh_private_key => "~/.ssh/id_rsa",
  :logger          => logger
}) do |camp|
  
  # not required here, since sequential is the default
  camp.sequential do

    camp.rsync(
      "local:~/my-data", 
      "remote:~/camp/my-data", 
      :on => [:rennes, :grenoble]
    )

    camp.export(
      "remote:~/camp/my-data", 
      :via => :http, 
      :port => 4567, 
      :on => [:rennes, :grenoble]
    )

    camp.parallel do
      camp.launch(
        40.instances, 
        :environment => "lenny-x64-base", 
        :having      => [
          :architecture.with(:smp_size.gt 4),
          :network_adapters.with(:interface.like(/infiniband/i))
        ],
        :notify      => "xmpp:crohr@jabber.grid5000.fr",
        :for         => 2.hours,
        :retry       => 3.times,
        :id          => :multicpu
      )

      camp.launch(
        20.instances, 
        :environment  => :default,
        :on           => [:rennes, :lille],
        :distribution => [10, 10],
        :having       => [
          :processor.with(:clock_speed.gt 2.8.G)
        ],
        :for          => 2.hours,
        :retry        => 2.times,
        :id           => :fast
      )
    end

    camp.execute(
      "hostname", 
      :on => camp[:multicpu].instances+camp[:fast].instances
    )    

    # Display campaign info and status
    camp.logger.info camp.to_s
    
    camp.wait {
      camp[:multicpu].finished? && camp[:fast].finished?
    }

    camp.graph(
      camp[:multicpu].instances+camp[:fast].instances, 
      :metrics => [:mem_free, :bytes_in, :bytes_out, :cpu_idle], 
      :resolution => 15
    )
    
  end
  
end.run!
