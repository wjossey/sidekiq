require '../sidekiq'
require 'sidekiq/backend/queue/redis'

Sidekiq.backend = Sidekiq::Backend::Queue::Redis.new
