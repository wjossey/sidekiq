require 'celluloid' 
require 'sidekiq/util'
module Sidekiq
  module Backend
    module Queue
      class SQS < Base        
        include Celluloid
        include Util

        TIMEOUT = 1
        BATCH = 10        

        def initialize(options={})
          #Right now doesn't do anything...
          #@queues = options[:queues] || registered_queues.map { |q| "queue:#{q}"}
          #@unique_queues = @queues.uniq          
        end

        #Simulates a blocking pop since there is no native blop in sqs
        def pop(queues)
          queues = ["my_queue"]
          if !buffer.empty?
            return queues.first, buffer.pop
          end

          if fetch_required?
            begin 
              received = false              
              Sidekiq.sqs do |sqs|
                queue = sqs.queues.named(queues.first)
                queue.receive_message(:limit => BATCH) do |msg|
                  received = true
                  @buffer << msg.body
                end
              end
              refetch(queues) if !received
            rescue => ex
              logger.error("Error fetching message: #{ex.inspect}")
              logger.error(ex.backtrace.first)
              refetch
            end
          end
        end

        #Deliver the payload to SQS
        def push(payload, queue="default")        
          Sidekiq.sqs do |sqs|      
            queues = ["my_queue"]
            queue = sqs.queues.named(queues.first)      
            if payload.is_a?(Array)
              results = []
              payload.each_slice(10) { |slice| results << queue(name).batch_send(slice)}
              #Just return true if we didn't blow up...
              true
            else
              result = queue.send_message(payload)
            end          
            !result.md5.nil?
          end
        end

        def schedule(payload, queue, at)
          raise "Scheduling a payload is not supported at this time with SQS"
        end

        private 

          #Our local buffer is used to store multiple results from SQS that are acquired in a batch fetch
          def buffer
            @buffer ||= []
          end

          def refetch(queues)
            sleep(TIMEOUT)
            after(0) { pop(queues) }
          end

          def fetch_required?
            buffer.size < BATCH
          end  
          def logger
            @logger ||= Sidekiq::Logging.logger
          end      
      end
    end
  end
end
