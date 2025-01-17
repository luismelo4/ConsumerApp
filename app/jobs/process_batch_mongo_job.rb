require 'countries'

class ProcessBatchMongoJob
  include Sidekiq::Worker
  
  MONGO_INSERT_BATCH_SIZE = 200
  
  def perform(batch, job_id)
    logger = Logger.new(File.join(Rails.root, 'log', 'process_batch_mongo_logs.log'))
    logger.level = Logger::INFO
    logger.info("Starting batch processing")
    log_memory_usage("Start", logger)
    @redis = Redis.new
    
    temp_batch = []
    seen_records = Set.new
    
    batch.each_with_index do |record, index|
      next unless valid_record?(record)
    
      product_data = normalize_data(record)
    
      unique_key = "#{product_data[:country]}_#{product_data[:product_id]}_#{product_data[:shop_name]}"
      next if seen_records.include?(unique_key)
    
      seen_records.add(unique_key)
      temp_batch << product_data
    
      if temp_batch.size >= MONGO_INSERT_BATCH_SIZE
        upsert_into_mongo(temp_batch, job_id, logger)
        temp_batch.clear
      end
    end
    
    upsert_into_mongo(temp_batch, job_id, logger) unless temp_batch.empty?
    
    @redis.incr("mongo_batches_processed_#{job_id}")
    
    logger.info("Batch processing completed")
    log_memory_usage("End", logger)
    
    check_for_merge(job_id)
  end
  
  private
  
  def upsert_into_mongo(batch_data, job_id, logger)
    timestamp = Time.now.utc
    
    operations = batch_data.map do |product_data|
      {
        update_one: {
          filter: { country: product_data[:country], product_id: product_data[:product_id], shop_name: product_data[:shop_name] },
          update: { 
            "$set" => {
              country: product_data[:country],
              brand: product_data[:brand],
              product_id: product_data[:product_id],
              product_name: product_data[:product_name],
              shop_name: product_data[:shop_name],
              product_category_id: product_data[:product_category_id],
              price: product_data[:price],
              url: product_data[:url],
              updated_at: timestamp
            }
          },
          upsert: true
        }
      }
    end
    
    begin
      MongoProduct.collection.bulk_write(operations)
    rescue => e
      logger.error("Error during bulk upsert into MongoDB: #{e.message}")
    end
  end
  
  def check_for_merge(job_id)
    if last_batch?(job_id)
      logger.info("Last batch detected, finalizing MongoDB processing.")
    end
  end
  
  def last_batch?(job_id)
    batches_enqueued = @redis.get("mongo_batches_enqueued_#{job_id}").to_i
    batches_processed = @redis.get("mongo_batches_processed_#{job_id}").to_i
    
    batches_enqueued == batches_processed && @redis.get("mongo_import_in_progress_#{job_id}") == "false"
  end
  
  def valid_record?(record)
    record['availability'] == true && record['price'].to_f > 0
  end
  
  def normalize_data(record)
    product_data = {
      country: normalize_country(record['country']),
      brand: record['brand'],
      product_id: record['sku'],
      product_name: record['model'],
      shop_name: normalize_shop_name(record['site'] || record['marketplaceseller']),
      product_category_id: record['categoryId'],
      price: record['price'],
      url: record['url']
    }
    logger.info("Normalized product data: #{product_data.inspect}")
    product_data
  end
  
  def normalize_country(country)
    country_codes = ISO3166::Country.codes
    pattern = /\b(?!\A)(#{country_codes.join('|')})\b/i
    country.gsub(pattern, "").strip
  end
    
  def normalize_shop_name(shop_name)
    shop_name.strip
  end
  
  def log_memory_usage(stage, logger)
    memory_usage = `ps -o rss= -p #{Process.pid}`.to_i
    logger.info("Memory usage at #{stage}: #{memory_usage} KB")
  end
end
