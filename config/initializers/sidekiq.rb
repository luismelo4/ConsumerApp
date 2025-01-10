Sidekiq.configure_server do |config|
  # Specify Redis server details
  config.redis = { url: 'redis://localhost:6379/0', namespace: 'sidekiq' }
end

Sidekiq.configure_client do |config|
  # Specify Redis server details
  config.redis = { url: 'redis://localhost:6379/0', namespace: 'sidekiq' }
end
