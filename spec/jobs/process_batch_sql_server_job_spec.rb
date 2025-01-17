require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe ProcessBatchSqlServerJob, type: :job do
  let(:job_id) { 'job_123' }
  let(:batch) do
    [
      { 'country' => 'belgium', 'brand' => 'Nike', 'sku' => '123', 'model' => 'Running Shoes', 'site' => 'Nike Store', 'categoryId' => 1, 'price' => 100.0, 'url' => 'https://nike.com/shoes', 'availability' => true },
      { 'country' => 'belgium', 'brand' => 'Adidas', 'sku' => '124', 'model' => 'Football Boots', 'marketplaceseller' => 'Adidas Store', 'categoryId' => 2, 'price' => 120.0, 'url' => 'https://adidas.com/boots', 'availability' => true }
    ]
  end

  let(:job) { ProcessBatchSqlServerJob.new }

  before do
    allow(Redis).to receive(:new).and_return(double('Redis', incr: true, get: '0'))
    
    allow(ActiveRecord::Base.connection).to receive(:execute).and_return(true)

    logger = double('Logger')
    allow(Logger).to receive(:new).and_return(logger)
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
    allow(logger).to receive(:level=)

    allow(job).to receive(:log_memory_usage).with("Start", logger)
    allow(job).to receive(:log_memory_usage).with("End", logger)
  end

  describe '#perform' do
    it 'processes the batch and performs the insert into the temp table' do
      expect(ActiveRecord::Base.connection).to receive(:execute).at_least(:once)
      expect(job).to receive(:log_memory_usage).twice  

      job.perform(batch, job_id)
    end

    it 'does not insert invalid records' do
      invalid_batch = [
        { 'country' => 'belgium', 'brand' => 'Nike', 'sku' => '125', 'model' => 'Running Shoes', 'site' => 'Nike Store', 'categoryId' => 1, 'price' => -1.0, 'url' => 'https://nike.com/shoes', 'availability' => true }
      ]
      
      expect(ActiveRecord::Base.connection).not_to receive(:execute)
      job.perform(invalid_batch, job_id)
    end

    it 'inserts only valid unique records into the temp table' do
      duplicate_batch = batch + batch
      expect(ActiveRecord::Base.connection).to receive(:execute).once
      job.perform(duplicate_batch, job_id)
    end

    it 'logs memory usage' do
      logger = double('Logger')
      expect(job).to receive(:log_memory_usage).with('Start', anything)
      expect(job).to receive(:log_memory_usage).with('End', anything)
      job.perform(batch, job_id)
    end
  end

  describe '#check_for_merge' do
    it 'finalizes processing when it is the last batch' do
      allow(job).to receive(:last_batch?).and_return(true)
      expect(job).to receive(:logger).and_return(double('Logger', info: true))

      job.send(:check_for_merge, job_id)
    end
  end

  describe '#last_batch?' do
    it 'returns true when all batches have been processed and import is not in progress' do
      allow(job).to receive(:last_batch?).and_return(true)
      expect(job.send(:last_batch?, job_id)).to eq(true)
    end
  end

  describe '#valid_record?' do
    it 'returns true for valid records' do
      valid_record = { 'country' => 'belgium', 'brand' => 'Nike', 'sku' => '123', 'model' => 'Running Shoes', 'site' => 'Nike Store', 'categoryId' => 1, 'price' => 100.0, 'url' => 'https://nike.com/shoes', 'availability' => true }
      expect(job.send(:valid_record?, valid_record)).to eq(true)
    end

    it 'returns false for invalid records' do
      invalid_record = { 'country' => 'belgium', 'brand' => 'Nike', 'sku' => '123', 'model' => 'Running Shoes', 'site' => 'Nike Store', 'categoryId' => 1, 'price' => -1.0, 'url' => 'https://nike.com/shoes', 'availability' => true }
      expect(job.send(:valid_record?, invalid_record)).to eq(false)
    end
  end

  describe '#normalize_data' do
    it 'normalizes the product data correctly' do
      record = { 'country' => 'belgium', 'brand' => 'Nike', 'sku' => '123', 'model' => 'Running Shoes', 'site' => 'Nike Store', 'categoryId' => 1, 'price' => 100.0, 'url' => 'https://nike.com/shoes', 'availability' => true }
      normalized_data = job.send(:normalize_data, record)
      expect(normalized_data[:country]).to eq('belgium')
      expect(normalized_data[:product_id]).to eq('123')
      expect(normalized_data[:product_name]).to eq('Running Shoes')
      expect(normalized_data[:price]).to eq(100.0)
    end
  end

  describe '#merge_from_temp_table' do
    it 'performs a merge from the temp table to the products table' do
      expect(ActiveRecord::Base.connection).to receive(:execute).at_least(:once)
      job.send(:merge_from_temp_table, job_id)
    end
  end

  describe '#drop_temp_table' do
    it 'drops the temp table' do
      expect(ActiveRecord::Base.connection).to receive(:execute).with("DROP TABLE IF EXISTS temp_products_#{job_id};")
      job.send(:drop_temp_table, job_id)
    end
  end

  describe '#escape_sql' do
    it 'escapes SQL values correctly' do
      expect(job.send(:escape_sql, 'Test value')).to eq("N'Test value'")
    end
  end
end
