require 'countries'

class ProcessBatchSqlServerJob
  include Sidekiq::Worker

  SQL_INSERT_BATCH_SIZE = 100

  def perform(batch, job_id)
    logger = Logger.new(File.join(Rails.root, 'log', 'process_batch_sqlserver_logs.log'))
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
  
      if temp_batch.size >= SQL_INSERT_BATCH_SIZE
        insert_into_temp_table(temp_batch, job_id, logger)
        temp_batch.clear
      end
    end
  
    insert_into_temp_table(temp_batch, job_id, logger) unless temp_batch.empty?
  
    @redis.incr("sqlserver_batches_processed_#{job_id}")
  
    logger.info("Batch processing completed")
    log_memory_usage("End", logger)
    
    check_for_merge(job_id)
  end

  private

  def insert_into_temp_table(batch_data, job_id, logger)
    table_name = "temp_products_#{job_id}"
    timestamp = Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')
  
    values = batch_data.map do |product_data|
      "(#{escape_sql(product_data[:country])}, #{escape_sql(product_data[:brand])}, " \
      "#{escape_sql(product_data[:product_id])}, #{escape_sql(product_data[:product_name])}, " \
      "#{escape_sql(product_data[:shop_name])}, #{escape_sql(product_data[:product_category_id])}, " \
      "#{escape_sql(product_data[:price])}, #{escape_sql(product_data[:url])}, " \
      "'#{timestamp}', '#{timestamp}')"
    end.join(", ")

    merge_sql = <<-SQL
      MERGE INTO #{table_name} AS target
      USING (VALUES #{values}) AS source (country, brand, product_id, product_name, shop_name, product_category_id, price, url, created_at, updated_at)
      ON target.country = source.country
      AND target.product_id = source.product_id
      AND target.shop_name = source.shop_name
      WHEN NOT MATCHED BY TARGET THEN
        INSERT (country, brand, product_id, product_name, shop_name, product_category_id, price, url, created_at, updated_at)
        VALUES (source.country, source.brand, source.product_id, source.product_name, source.shop_name, source.product_category_id, source.price, source.url, source.created_at, source.updated_at);
    SQL

    begin
      ActiveRecord::Base.connection.execute(merge_sql)
    rescue ActiveRecord::StatementInvalid => e
      logger.error("SQL Error during temp table batch insert: #{e.message}.")
    rescue => e
      logger.error("Error during batch insert into temp table: #{e.message}")
    end
  end

  def check_for_merge(job_id)
    if last_batch?(job_id)
      logger.info("Last batch detected, performing merge from temp table to products table.")
      merge_from_temp_table(job_id)
      drop_temp_table(job_id)
    end
  end

  def merge_from_temp_table(job_id)
    table_name = "temp_products_#{job_id}"
    merge_sql = <<-SQL
      MERGE INTO products AS target
      USING #{table_name} AS source
      ON target.product_id = source.product_id
      AND target.country = source.country
      AND target.shop_name = source.shop_name
      WHEN MATCHED THEN
        UPDATE SET 
          target.country = source.country,
          target.brand = source.brand,
          target.product_id = source.product_id,
          target.product_name = source.product_name,
          target.shop_name = source.shop_name,
          target.product_category_id = source.product_category_id,
          target.price = source.price,
          target.url = source.url,
          target.updated_at = source.updated_at
      WHEN NOT MATCHED THEN
        INSERT (country, brand, product_id, product_name, shop_name, product_category_id, price, url, created_at, updated_at)
        VALUES (source.country, source.brand, source.product_id, source.product_name, source.shop_name, source.product_category_id, source.price, source.url, source.created_at, source.updated_at);
    SQL

    ActiveRecord::Base.connection.execute(merge_sql)
  end

  def drop_temp_table(job_id)
    table_name = "temp_products_#{job_id}"
    sql = "DROP TABLE IF EXISTS #{table_name};"
    ActiveRecord::Base.connection.execute(sql)
    Rails.logger.info("Temporary table #{table_name} dropped successfully.")
  end

  def last_batch?(job_id)
    batches_enqueued = @redis.get("sqlserver_batches_enqueued_#{job_id}").to_i
    batches_processed = @redis.get("sqlserver_batches_processed_#{job_id}").to_i

    logger.info("Batches enqueued: #{batches_enqueued}, processed: #{batches_processed}")
    
    batches_enqueued == batches_processed && @redis.get("sqlserver_import_in_progress_#{job_id}") == "false"
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

  def escape_sql(value)
    ActiveRecord::Base.connection.quote(value.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?'))
  end

  def log_memory_usage(stage, logger)
    memory_usage = `ps -o rss= -p #{Process.pid}`.to_i
    logger.info("Memory usage at #{stage}: #{memory_usage} KB")
  end
end
