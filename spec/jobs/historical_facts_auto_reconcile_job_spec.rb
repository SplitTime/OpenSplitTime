require "rails_helper"

RSpec.describe HistoricalFactsAutoReconcileJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(event, current_user: user) }
  let(:event) { events(:ramble) }
  let(:user) { users(:admin_user) }

  it "queues the job" do
    expect { job }.to change(described_class.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it "calls HistoricalFactAutoReconciler with the correct arguments" do
    expect(HistoricalFactAutoReconciler).to receive(:reconcile).with(event)
    perform_enqueued_jobs { job }
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
