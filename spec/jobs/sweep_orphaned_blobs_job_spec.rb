require "rails_helper"

RSpec.describe SweepOrphanedBlobsJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later }

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "queues the job" do
    expect { job }.to change(described_class.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it "executes perform" do
    expect { perform_enqueued_jobs { job } }.not_to raise_error
  end
end
