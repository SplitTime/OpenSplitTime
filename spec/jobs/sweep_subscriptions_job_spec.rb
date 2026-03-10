require "rails_helper"

RSpec.describe SweepSubscriptionsJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later }

  it "queues the job" do
    expect { job }.to change(described_class.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it "executes perform and sends a job report" do
    expect(AdminMailer).to receive_message_chain(:job_report, :deliver_now)
    perform_enqueued_jobs { job }
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
