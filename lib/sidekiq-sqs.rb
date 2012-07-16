require 'sidekiq'
require 'aws-sdk'
require 'sidekiq/backend/queue/sqs'
require 'sidekiq/sqs_connection'

Sidekiq.backend = Sidekiq::Backend::Queue::SQS.new
