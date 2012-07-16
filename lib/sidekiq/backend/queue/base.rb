module Sidekiq
  module Backend
    module Queue
      class Base
        def registered_workers
          Sidekiq.redis { |x| x.smembers('workers') }
        end

        def registered_queues
          Sidekiq.redis { |x| x.smembers('queues') }
        end

        def push(payload, queue="default")
          raise "There is no base implementation for pushing"
        end

        def pop
          raise "There is no base implementation for pop"
        end

        def schedule(payload, queue, at)
          raise "There is no base implementation for scheduling"
        end
      end
    end
  end
end