require 'redis'
require 'redis-namespace'
require 'connection_pool'

Sidekiq.configure_server do |config|
  # Specify Redis server details with namespace and connection pool
  config.redis = ConnectionPool.new(size: 64) do
    Redis::Namespace.new('sidekiq', redis: Redis.new(url: 'redis://localhost:6379/0'))
  end

  # Set logger explicitly
  config.logger = Logger.new(Rails.root.join('log', 'sidekiq.log'))
  config.logger.level = Logger::INFO

  # Set concurrency level
  config.options[:concurrency] = 24  # Adjust this value based on your server's resources

  # Middleware configuration (optional)
  config.server_middleware do |chain|
    # Add custom middleware here
  end
end

Sidekiq.configure_client do |config|
  # Specify Redis server details with namespace and connection pool
  config.redis = ConnectionPool.new(size: 64) do
    Redis::Namespace.new('sidekiq', redis: Redis.new(url: 'redis://localhost:6379/0'))
  end

  # Use the default Rails logger for the client side (optional)
  config.logger = Rails.logger
  config.logger.level = Logger::INFO
end