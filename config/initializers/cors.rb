Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins 'http://localhost:3000'  # Replace with your frontend URL
      resource '*', headers: :any, methods: [:get, :post, :options]
    end
  end
  