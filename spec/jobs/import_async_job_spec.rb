require "rails_helper"

RSpec.describe ImportAsyncJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(import_job.id) }

  let!(:import_job) { create(:import_job) }

  before do
    allow(Etl::AsyncImporter).to receive(:import!)
    clear_enqueued_jobs
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "queues the job" do
    expect { job }.to change(described_class.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it "calls Etl::AsyncImporter with the correct arguments" do
    expect(Etl::AsyncImporter).to receive(:import!).with(import_job)
    perform_enqueued_jobs { job }
  end
end
