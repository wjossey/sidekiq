module Sidekiq  
  module Backend
    module Queue
      class Redis < Base

        TIMEOUT = 1

        def push(payload, queue="default")          
          _, pushed = Sidekiq.redis do |conn|
            conn.multi do 
              conn.sadd('queues', queue)
              conn.rpush("queue:#{queue}", payload)
            end            
          end
          pushed
        end

        #Pop the next item off the list of given queues. Returns the queue
        #that it was found on & the message
        def pop(queues)
          @queues = queues
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
            queues_sample = queues.sample(unique_queues.size).uniq
            queues_sample.concat(unique_queues - queues_sample)
            queues_sample << TIMEOUT
          end

          def unique_queues
            @unique_queues ||= queues.uniq
          end
      end
    end
  end
end