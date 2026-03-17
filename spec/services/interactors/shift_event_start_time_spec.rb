require "rails_helper"

RSpec.describe Interactors::ShiftEventStartTime do
  subject { described_class.new(event, new_start_time: new_start_time) }

  let(:event) { events(:hardrock_2014) }
  let(:effort) { efforts(:hardrock_2014_finished_first) }

  describe "#initialize" do
    let(:new_start_time) { event.scheduled_start_time_local + 1.hour }

    context "when valid arguments are provided" do
      it "initializes without error" do
        expect { subject }.not_to raise_error
      end
    end

    context "when event is nil" do
      it "raises an ArgumentError" do
        expect { described_class.new(nil, new_start_time: new_start_time) }.to raise_error(ArgumentError, /must include event/)
      end
    end

    context "when event is not an Event" do
      it "raises an ArgumentError" do
        expect { described_class.new("not an event", new_start_time: new_start_time) }.to raise_error(ArgumentError, /must be an Event/)
      end
    end

    context "when new_start_time is nil" do
      it "raises an ArgumentError" do
        expect { described_class.new(event, new_start_time: nil) }.to raise_error(ArgumentError, /must include new_start_time/)
      end
    end
  end

  describe "#perform!" do
    let(:response) { subject.perform! }
    let(:split_time) { effort.ordered_split_times.first }

    context "when the start time is shifted forward" do
      let(:new_start_time) { event.scheduled_start_time_local + 1.hour }

      it "shifts the event, effort, and split_time times forward" do
        original_event_time = event.scheduled_start_time
        original_split_time = split_time.absolute_time

        response

        expect(event.reload.scheduled_start_time).to eq(original_event_time + 1.hour)
        expect(split_time.reload.absolute_time).to eq(original_split_time + 1.hour)
      end

      it "returns a successful response" do
        expect(response).to be_successful
        expect(response.message).to include("shifted")
      end
    end

    context "when the start time is shifted backward" do
      let(:new_start_time) { event.scheduled_start_time_local - 1.hour }

      it "shifts the event and split_time times backward" do
        original_event_time = event.scheduled_start_time
        original_split_time = split_time.absolute_time

        response

        expect(event.reload.scheduled_start_time).to eq(original_event_time - 1.hour)
        expect(split_time.reload.absolute_time).to eq(original_split_time - 1.hour)
      end

      it "returns a successful response" do
        expect(response).to be_successful
      end
    end

    context "when the new start time equals the current start time" do
      let(:new_start_time) { event.scheduled_start_time_local }

      it "does not change any times" do
        original_event_time = event.scheduled_start_time
        original_split_time = split_time.absolute_time

        response

        expect(event.reload.scheduled_start_time).to eq(original_event_time)
        expect(split_time.reload.absolute_time).to eq(original_split_time)
      end

      it "returns a successful response with unchanged message" do
        expect(response).to be_successful
        expect(response.message).to include("unchanged")
      end
    end
  end
end
