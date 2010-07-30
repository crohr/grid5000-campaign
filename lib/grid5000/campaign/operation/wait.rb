module Grid5000
  class Campaign
    module Operation
      class Wait < Base

        # Helper class to be used with EM::Synchrony.sync
        class Timer
          include EventMachine::Deferrable
          def run(seconds, &block)
            EM.add_timer(seconds, &block)
            self
          end
        end

        INFINITY = 1.0/0.0

        attr_reader :condition

        def initialize(*args, &block)
          super(*args)
          @condition = block
        end # def initialize

        def execute!
          @started_at ||= Time.now.to_i
          EM::Synchrony.sync Timer.new.run([
            60.seconds, walltime
          ].min) do
            elapsed = Time.now.to_i-@started_at
            if walltime >= elapsed
              if condition
                condition.call(campaign)
              else
                true
              end
            else
              (condition && condition.call(campaign)) || execute!
            end
          end
        end # def execute!

        def walltime
          @walltime ||= (config[:seconds] || INFINITY)
        end # def walltime

      end # class Wait
    end # module Operation
  end # class Campaign
end # module Grid5000
