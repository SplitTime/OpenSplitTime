require "rails_helper"

RSpec.describe ExportAsyncJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(export_job.id) }
  let!(:export_job) { create(:export_job) }

  before do
    allow(Exporter::AsyncExporter).to receive(:export!)
    clear_enqueued_jobs
  end

  it "queues the job" do
    expect { job }.to change(described_class.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it "calls Exporter::AsyncExporter with the correct arguments" do
    expect(Exporter::AsyncExporter).to receive(:export!).with(export_job)
    perform_enqueued_jobs { job }
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
