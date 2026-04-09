require "rails_helper"

RSpec.describe UpdateEffortsStatusJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(event_group, **options) }

  let(:event_group) { event_groups(:rufa_2017) }
  let(:options) { { current_user: users(:admin_user) } }

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "queues the job" do
    expect { job }.to change(described_class.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it "calls UpdateEffortsStatus with the event group efforts" do
    expect(Interactors::UpdateEffortsStatus).to receive(:perform!).and_call_original
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
