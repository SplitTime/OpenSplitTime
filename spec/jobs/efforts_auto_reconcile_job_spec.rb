require "rails_helper"

RSpec.describe EffortsAutoReconcileJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(event_group, **options) }

  let(:event_group) { event_groups(:ramble) }
  let(:options) { { current_user: users(:admin_user) } }

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "queues the job" do
    expect { job }.to change(described_class.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it "calls EffortAutoReconciler with the correct arguments" do
    expect(EffortAutoReconciler).to receive(:reconcile).with(event_group, {})
    perform_enqueued_jobs { job }
  end

  it "broadcasts a flash message on completion" do
    expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
      event_group,
      target: "flash",
      partial: "layouts/broadcast_flash",
      locals: hash_including(level: :success, message: anything)
    )
    perform_enqueued_jobs { job }
  end
end
