module Sidekiq
  module Backend
    module Queue
      class Base
        def create(options={})

        end

        def push(payload, queue="default")
          raise "There is no base implementation for pushing"
        end

        def pop(queue="default")
          raise "There is no base implementation for pop"
        end

        def schedule(payload, queue, at)
          raise "There is no base implementation for scheduling"
        end        
      end
    end
  end
end