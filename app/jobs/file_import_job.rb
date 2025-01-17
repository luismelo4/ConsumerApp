require 'json'
require 'sidekiq'
require 'logger'
require 'oj'

class FileImportJob
  include Sidekiq::Worker

  SQLSERVER_BATCH_SIZE = 100
  MONGODB_BATCH_SIZE = 200

  def perform(file_path)
    @logger = Logger.new(File.join(Rails.root, 'log', 'file_import_logs.log'))
    @logger.level = Logger::INFO
    start_time = Time.now
    @job_id = jid
    @redis = Redis.new
    @redis.set("job:#{@job_id}:start", true)
    @redis.set("sqlserver_import_in_progress_#{@job_id}", true)
    @redis.set("sqlserver_batches_enqueued_#{@job_id}", 0)
    @redis.set("sqlserver_batches_processed_#{@job_id}", 0)
    @redis.set("mongo_import_in_progress_#{@job_id}", true)
    @redis.set("mongo_batches_enqueued_#{@job_id}", 0)
    @redis.set("mongo_batches_processed_#{@job_id}", 0)

    create_temp_table()

    @logger.info("Processing file: #{file_path} for job ID: #{@job_id}")
    @logger.info("Starting file import for #{file_path}")
    log_memory_usage("Start", @logger)

    @sqlserver_batch = []
    @mongodb_batch = []
    @total_processed = 0

    begin
      file_stream = File.open(file_path, 'r')
      handler = SajHandler.new(self)
      Oj.saj_parse(handler, file_stream)

      enqueue_sqlserver_batch(@sqlserver_batch, @logger) unless @sqlserver_batch.empty?
      enqueue_mongodb_batch(@mongodb_batch, @logger) unless @mongodb_batch.empty?
    rescue Oj::ParseError => e
      @logger.error("JSON parsing error: #{e.message}")
    rescue => e
      @logger.error("Unexpected error: #{e.message}")
      @logger.error(e.backtrace.join("\n"))
    ensure
      file_stream.close if file_stream
    end

    end_time = Time.now
    total_duration = end_time - start_time

    
    @logger.info("File import completed in #{total_duration} seconds")
    log_memory_usage("End", @logger)
    @redis.set("sqlserver_import_in_progress_#{@job_id}", false)
    @redis.set("mongo_import_in_progress_#{@job_id}", false)
  end

  def create_temp_table
    table_name = "temp_products_#{@job_id}"
    constraint_name = "uc_temp_products_#{@job_id}"
    sql = <<-SQL
      IF OBJECT_ID('#{table_name}', 'U') IS NOT NULL
      DROP TABLE #{table_name};
      CREATE TABLE #{table_name} (
        id INT IDENTITY(1,1) PRIMARY KEY,
        country NVARCHAR(50),
        brand NVARCHAR(100) NULL,
        product_id NVARCHAR(4000),
        product_name NVARCHAR(200) NULL,
        shop_name NVARCHAR(100), 
        product_category_id INT NULL,
        price DECIMAL(10,2) NULL,
        url NVARCHAR(4000) NULL,
        created_at DATETIME2(6),
        updated_at DATETIME2(6),
        CONSTRAINT #{constraint_name} UNIQUE (country, product_id, shop_name)
      );
    SQL
    
    ActiveRecord::Base.connection.execute(sql)
    @logger.info("Temporary table #{table_name} created successfully with a unique constraint on country, product_id, and shop_name.")
  end

  def enqueue_sqlserver_batch(batch, logger)
    @redis.incr("sqlserver_batches_enqueued_#{@job_id}")
    if batch.any?
      @logger.info("Enqueuing ProcessBatchSqlServerJob for SQL Server batch: #{batch.size}")
      ProcessBatchSqlServerJob.perform_async(batch, @job_id)
    end
    batch.clear
  end

  def enqueue_mongodb_batch(batch, logger)
    @redis.incr("mongo_batches_enqueued_#{@job_id}")
    if batch.any?
      @logger.info("Enqueuing ProcessBatchMongoJob for MongoDB batch: #{batch.size}")
      ProcessBatchMongoJob.perform_async(batch, @job_id)
    end
    batch.clear
  end

  def process_object(object, logger)
    if object.is_a?(Array)
      object.each do |item|
        if @sqlserver_batch.size < SQLSERVER_BATCH_SIZE
          @sqlserver_batch << item
        else
          enqueue_sqlserver_batch(@sqlserver_batch, logger)
          @sqlserver_batch << item
        end

        if @mongodb_batch.size < MONGODB_BATCH_SIZE
          @mongodb_batch << item
        else
          enqueue_mongodb_batch(@mongodb_batch, logger)
          @mongodb_batch << item
        end
      end
    elsif object.is_a?(Hash)
      if @sqlserver_batch.size < SQLSERVER_BATCH_SIZE
        @sqlserver_batch << object
      else
        enqueue_sqlserver_batch(@sqlserver_batch, logger)
        @sqlserver_batch << object
      end

      if @mongodb_batch.size < MONGODB_BATCH_SIZE
        @mongodb_batch << object
      else
        enqueue_mongodb_batch(@mongodb_batch, logger)
        @mongodb_batch << object
      end
    else
      logger.error("Unexpected JSON structure: #{object}")
    end
  end

  def log_memory_usage(stage, logger)
    memory_usage = `ps -o rss= -p #{Process.pid}`.to_i
    logger.info("Memory usage at #{stage}: #{memory_usage} KB")
  end
end

class SajHandler
  def initialize(job)
    @job = job
    @current_hash = nil
    @current_array = nil
  end

  def hash_start(key)
    @current_hash = {}
  end

  def hash_end(key)
    @job.process_object(@current_hash, @job.instance_variable_get(:@logger))
    @job.instance_variable_set(:@total_processed, @job.instance_variable_get(:@total_processed) + 1)
    @job.instance_variable_get(:@logger).info("Processed #{@job.instance_variable_get(:@total_processed)} records so far") if @job.instance_variable_get(:@total_processed) % 100_000 == 0
  end

  def array_start(key)
    @current_array = []
  end

  def array_end(key)
    @job.process_object(@current_array, @job.instance_variable_get(:@logger))
    @job.instance_variable_set(:@total_processed, @job.instance_variable_get(:@total_processed) + 1)
    @job.instance_variable_get(:@logger).info("Processed #{@job.instance_variable_get(:@total_processed)} records so far") if @job.instance_variable_get(:@total_processed) % 100_000 == 0
  end

  def add_value(value, key)
    value = value.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?') if value.is_a?(String)
    if @current_hash
      @current_hash[key] = value
    elsif @current_array
      @current_array << value
    end
  end
end
