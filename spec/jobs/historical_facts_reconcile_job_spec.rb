require "rails_helper"

RSpec.describe HistoricalFactsReconcileJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(event, current_user: user, personal_info_hash: personal_info_hash, person_id: person.id) }
  let(:event) { events(:ramble) }
  let(:user) { users(:admin_user) }
  let(:person) { people(:bruno_fadel) }
  let(:personal_info_hash) { "abc123" }

  it "queues the job" do
    expect { job }.to change(described_class.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it "calls HistoricalFactReconciler with the correct arguments" do
    expect(HistoricalFactReconciler).to receive(:reconcile).with(event, personal_info_hash: personal_info_hash, person_id: person.id)
    perform_enqueued_jobs { job }
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
