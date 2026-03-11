require "rails_helper"

RSpec.describe EventUpdateStartTimeJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(event, options) }

  let(:event) { events(:ramble) }
  let(:options) { { new_start_time: "2017-10-01 08:00:00", current_user: users(:admin_user) } }

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "queues the job" do
    expect { job }.to change(described_class.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it "calls Interactors::ShiftEventStartTime with the correct arguments" do
    result = Interactors::Response.new(errors: [])
    allow(Interactors::ShiftEventStartTime).to receive(:perform!).with(event, { new_start_time: "2017-10-01 08:00:00" }).and_return(result)
    perform_enqueued_jobs { job }
    expect(Interactors::ShiftEventStartTime).to have_received(:perform!).with(event, { new_start_time: "2017-10-01 08:00:00" })
  end
end
