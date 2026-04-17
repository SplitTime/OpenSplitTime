require "rails_helper"

RSpec.describe EventUpdateStartTimeJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(event, **options) }

  let(:event) { events(:ramble) }
  let(:event_group) { event.event_group }
  let(:options) { { new_start_time: "2017-10-01 08:00:00", current_user: users(:admin_user) } }

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "queues the job" do
    expect { job }.to change(described_class.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it "calls Interactors::ShiftEventStartTime with keyword arguments" do
    result = Interactors::Response.new(errors: [])
    allow(Interactors::ShiftEventStartTime).to receive(:perform!)
      .with(event, new_start_time: "2017-10-01 08:00:00").and_return(result)

    perform_enqueued_jobs { job }

    expect(Interactors::ShiftEventStartTime).to have_received(:perform!)
      .with(event, new_start_time: "2017-10-01 08:00:00")
  end

  it "shifts the event start time without error" do
    perform_enqueued_jobs { job }

    expect(event.reload.scheduled_start_time_local.to_s).to include("2017-10-01")
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

  it "broadcasts a refresh on completion" do
    expect(Turbo::StreamsChannel).to receive(:broadcast_refresh_to).with(event_group)

    perform_enqueued_jobs { job }
  end

  describe "validation" do
    context "when event is not an Event" do
      it "raises ArgumentError" do
        expect { described_class.new.perform("not an event", **options) }.to raise_error(ArgumentError, "event must be an Event")
      end
    end
  end
end
