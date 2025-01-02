require "rails_helper"

RSpec.describe Interactors::BulkDeleteEventGroupTimes do
  subject { described_class.new(event_group) }
  let(:event_group) { event_groups(:sum) }

  describe "#perform!" do
    context "when no errors occur" do
      it "deletes all split times" do
        expect(event_group.split_times.count).to be_positive
        expect { subject.perform! }.to change { event_group.split_times.count }.from(anything).to(0)
      end

      it "deletes all raw times" do
        expect(event_group.raw_times.count).to be_positive
        expect { subject.perform! }.to change { event_group.raw_times.count }.from(anything).to(0)
      end

      it "touches the event group and each event" do
        subject.perform!
        expect(event_group.reload.updated_at).to be_within(1.second).of(Time.current)
        event_group.events.each { |event| expect(event.reload.updated_at).to be_within(1.second).of(Time.current) }
      end

      it "returns a response with a descriptive message" do
        raw_times_count = event_group.raw_times.count
        split_times_count = event_group.split_times.count
        response = subject.perform!

        expect(response).to be_a(Interactors::Response)
        expect(response).to be_successful
        expect(response.message).to include("Deleted")
        expect(response.message).to include("#{raw_times_count} raw times")
        expect(response.message).to include("#{split_times_count} split times")
      end
    end

    context "when an error occurs" do
      before { allow_any_instance_of(ActiveRecord::Relation).to receive(:delete_all).and_raise ActiveRecord::ActiveRecordError, "a thing happened" }

      it "does not delete split times or raw times" do
        expect { subject.perform! }.to not_change { event_group.split_times.count }
                                         .and not_change { event_group.raw_times.count }
      end

      it "returns a response with errors" do
        response = subject.perform!
        expect(response).not_to be_successful
        expect(response.errors).to be_present
        expect(response.errors.first[:detail].to_s).to include("a thing happened")
      end
    end
  end
end
