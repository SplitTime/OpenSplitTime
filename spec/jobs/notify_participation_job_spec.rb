require "rails_helper"

RSpec.describe NotifyParticipationJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(effort.id) }
  let(:effort) { efforts(:ramble_finished_first) }

  it "queues the job" do
    expect { job }.to change(described_class.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it "calls ParticipationNotifier with the correct arguments" do
    response = Interactors::Response.new(errors: ["not sent"])
    allow(ParticipationNotifier).to receive(:publish).and_return(response)
    expect(ParticipationNotifier).to receive(:publish)
    perform_enqueued_jobs { job }
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
