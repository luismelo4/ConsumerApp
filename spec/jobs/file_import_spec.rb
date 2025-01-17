require 'rails_helper'
require 'sidekiq/testing'
require_relative '../../app/jobs/file_import_job'

RSpec.describe FileImportJob, type: :job do
    before do
      @logger = instance_double(Logger, level=:any)
      allow(Logger).to receive(:new).and_return(@logger)
      allow(@logger).to receive(:level=).with(Logger::INFO)
  
      @redis = instance_double(Redis)
      allow(Redis).to receive(:new).and_return(@redis)
      allow(@redis).to receive(:set).and_return(true)
      allow(@redis).to receive(:incr).and_return(1)
  
      @job = FileImportJob.new
      @job.instance_variable_set(:@redis, @redis)
      @job.instance_variable_set(:@sqlserver_batch, [])
      @job.instance_variable_set(:@mongodb_batch, [])
      @job.instance_variable_set(:@total_processed, 0)
    end
  
    describe '#perform' do
      it 'logs the start and end of the file import' do
        file_path = 'spec/fixtures/data2.json'
  
        allow(@logger).to receive(:info)
        expect(@logger).to receive(:info).with(/Starting file import/)
        expect(@logger).to receive(:info).with(/File import completed/)
  
        expect(ProcessBatchSqlServerJob).to receive(:perform_async).once
        expect(ProcessBatchMongoJob).to receive(:perform_async).once
  
        expect(@redis).to receive(:incr).with("sqlserver_batches_enqueued_#{@job.jid}")
        expect(@redis).to receive(:incr).with("mongo_batches_enqueued_#{@job.jid}")
  
        @job.perform(file_path)
      end
  
      it 'sets redis flags for job start and completion' do
        file_path = 'spec/fixtures/data2.json'
  
        allow(@logger).to receive(:info)
        expect(@redis).to receive(:set).with("job:#{@job.jid}:start", true)
        expect(@redis).to receive(:set).with("sqlserver_import_in_progress_#{@job.jid}", true)
  
        @job.perform(file_path)
      end
  
      it 'handles JSON parsing errors gracefully' do
        file_path = 'spec/fixtures/invalid.json'
  
        allow(@logger).to receive(:info)

        expect(@logger).to receive(:error).with(/JSON parsing error/)
  
        @job.perform(file_path)
      end
  
      it 'sets redis flags to false upon job completion' do
        file_path = 'spec/fixtures/data2.json'

        allow(@logger).to receive(:info)
  
        expect(@redis).to receive(:set).with("sqlserver_import_in_progress_#{@job.jid}", false)
        expect(@redis).to receive(:set).with("mongo_import_in_progress_#{@job.jid}", false)
  
        @job.perform(file_path)
      end
    end
  end
  