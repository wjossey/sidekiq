module Sidekiq  
  module Backend
    module Queue
      class Redis < Base

        TIMEOUT = 1

        def create(options={})
          @queues = options[:queues] || registered_queues.map { |q| "queue:#{q}"}
          @unique_queues = @queues.uniq
        end

        def push(payload, queue="default")          
          _, pushed = Sidekiq.redis do |conn|
            conn.multi do 
              conn.sadd('queues', queue)
              conn.rpush("queue:#{queue}", payload)
            end            
          end
          pushed
        end

        def pop(queue="default")
          msg = nil
          Sidekiq.redis { |conn| queue, msg = conn.blpop(*queues_cmd) }
        end

        def schedule(payload, queue, at)
          Sidekiq.redis do |conn|
            pushed = (conn.zadd('schedule', at.to_s, payload) == 1)
          end          
        end

        private 

          # Creating the Redis#blpop command takes into account any
          # configured queue weights. By default Redis#blpop returns
          # data from the first queue that has pending elements. We
          # recreate the queue command each time we invoke Redis#blpop
          # to honor weights and avoid queue starvation.
          def queues_cmd
            queues = @queues.sample(@unique_queues.size).uniq
            queues.concat(@unique_queues - queues)
            queues << TIMEOUT
          end
      end
    end
  end
end