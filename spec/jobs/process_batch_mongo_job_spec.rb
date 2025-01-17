require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe ProcessBatchMongoJob, type: :job do
  let(:job_id) { 'job_123' }
  let(:batch) do
    [
      { 'country' => 'belgium', 'brand' => 'Nike', 'sku' => '123', 'model' => 'Running Shoes', 'site' => 'Nike Store', 'categoryId' => 1, 'price' => 100.0, 'url' => 'https://nike.com/shoes', 'availability' => true },
      { 'country' => 'belgium', 'brand' => 'Adidas', 'sku' => '124', 'model' => 'Football Boots', 'marketplaceseller' => 'Adidas Store', 'categoryId' => 2, 'price' => 120.0, 'url' => 'https://adidas.com/boots', 'availability' => true }
    ]
  end

  let(:job) { ProcessBatchMongoJob.new }

  before do
    allow(Redis).to receive(:new).and_return(double('Redis', incr: true, get: '0'))
    
    allow(MongoProduct).to receive(:collection).and_return(double('MongoProductCollection', bulk_write: true))

    logger = double('Logger')
    allow(Logger).to receive(:new).and_return(logger)
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
    allow(logger).to receive(:level=)

    allow(job).to receive(:log_memory_usage).with('Start', anything)
    allow(job).to receive(:log_memory_usage).with('End', anything)
  end

  describe '#perform' do
    it 'processes the batch and performs the upsert into MongoDB' do
      expect(MongoProduct.collection).to receive(:bulk_write).once
      expect(job).to receive(:log_memory_usage).twice  

      job.perform(batch, job_id)
    end

    it 'does not insert invalid records' do
      invalid_batch = [
        { 'country' => 'belgium', 'brand' => 'Nike', 'sku' => '125', 'model' => 'Running Shoes', 'site' => 'Nike Store', 'categoryId' => 1, 'price' => -1.0, 'url' => 'https://nike.com/shoes', 'availability' => true }
      ]
      
      expect(MongoProduct.collection).not_to receive(:bulk_write)
      job.perform(invalid_batch, job_id)
    end

    it 'ensures that duplicate records are not inserted' do
      duplicate_batch = batch + batch  
      expect(MongoProduct.collection).to receive(:bulk_write).once
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
end
