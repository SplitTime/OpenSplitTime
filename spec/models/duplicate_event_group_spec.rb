require "rails_helper"

RSpec.describe DuplicateEventGroup, type: :model do
  let(:event_group) { event_groups(:sum) }
  let(:user) { users(:admin_user) }
  let(:new_name) { "SUM Duplicate" }
  let(:new_start_date) { "2025-06-01" }

  describe "#create" do
    subject do
      described_class.create(existing_id: event_group.id, new_name: new_name,
                             new_start_date: new_start_date, created_by: user.id)
    end

    context "with valid params" do
      it "creates a new event group" do
        expect { subject }.to change(EventGroup, :count).by(1)
      end

      it "creates events matching the original" do
        expect { subject }.to change(Event, :count).by(event_group.events.count)
      end

      it "sets the new name" do
        expect(subject.new_event_group.name).to eq(new_name)
      end

      it "sets concealed to true" do
        expect(subject.new_event_group.concealed).to be true
      end

      it "sets created_by to the provided user" do
        expect(subject.new_event_group.created_by).to eq(user.id)
      end

      it "sets created_by on duplicated events" do
        subject.new_event_group.events.each do |event|
          expect(event.created_by).to eq(user.id)
        end
      end
    end

    context "when the source event group has a webhook token" do
      before { event_group.update_column(:webhook_token, SecureRandom.base58(24)) }

      it "does not copy the webhook token from the source" do
        expect(subject.new_event_group.webhook_token).not_to eq(event_group.reload.webhook_token)
      end

      it "creates successfully without a unique constraint violation" do
        expect { subject }.to change(EventGroup, :count).by(1)
      end
    end

    context "with a blank name" do
      let(:new_name) { "" }

      it "does not create an event group" do
        expect { subject }.not_to change(EventGroup, :count)
      end

      it "is not valid" do
        expect(subject).not_to be_valid
      end
    end

    context "with a blank date" do
      let(:new_start_date) { nil }

      it "does not create an event group" do
        expect { subject }.not_to change(EventGroup, :count)
      end

      it "is not valid" do
        expect(subject).not_to be_valid
      end
    end

    context "with a duplicate name" do
      let(:new_name) { event_group.name }

      it "does not create an event group" do
        expect { subject }.not_to change(EventGroup, :count)
      end

      it "is not valid" do
        expect(subject).not_to be_valid
      end
    end
  end
end
