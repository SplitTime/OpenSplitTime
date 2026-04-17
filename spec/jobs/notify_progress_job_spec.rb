require "rails_helper"

RSpec.describe NotifyProgressJob do
  include BitkeyDefinitions

  subject { described_class.new }

  let(:perform_notification) { subject.perform(effort_id, split_time_ids) }

  let(:effort_id) { effort.id }
  let(:event) { events(:rufa_2017_24h) }
  let(:effort) { efforts(:rufa_2017_24h_progress_lap6) }
  let(:splits) { event.splits }

  describe "#perform" do
    let(:split_time_ids) { notification_split_times.pluck(:id) }
    let(:successful_response) { Interactors::Response.new(errors: [], resources: {}) }
    let(:unsuccessful_response) { Interactors::Response.new(errors: ["An error happened"], resources: {}) }
    let(:notification_split_times) { effort.ordered_split_times.last(2) }
    let(:split_time_total_distance) { notification_split_times.last.total_distance }

    context "when arguments are valid, the effort is notifiable, and the notification is timely" do
      before do
        effort.update(topic_resource_key: "aws_mock_key")
        travel_to(notification_split_times.last.absolute_time + 1.hour)
      end

      context "when no farther notification exists" do
        it "sends a message to ProgressNotifier" do
          allow(ProgressNotifier).to receive(:publish).and_return(successful_response)
          perform_notification
          expect(ProgressNotifier).to have_received(:publish)
        end

        it "creates notifications" do
          expect { perform_notification }.to change(Notification, :count).by(1)
          notification = Notification.last
          expect(notification.effort_id).to eq(effort.id)
          expect(notification.distance).to eq(notification_split_times.last.total_distance)
          expect(notification.bitkey).to eq(notification_split_times.last.bitkey)
          expect(notification.topic_resource_key).to eq(effort.topic_resource_key)
          expect(notification.subject).to eq("Update for Progress Lap6 at RUFA 2017 (24H) from OpenSplitTime")
        end

        it "stores distinct follower_ids when a user has multiple subscriptions" do
          user = users(:admin_user)
          Subscription.create!(user: user, subscribable: effort, protocol: :email,
                               endpoint: user.email, resource_key: "arn:aws:sns:us-west-2:123:test-email")
          Subscription.create!(user: user, subscribable: effort, protocol: :sms,
                               endpoint: user.phone, resource_key: "arn:aws:sns:us-west-2:123:test-sms")

          perform_notification
          notification = Notification.last
          expect(notification.follower_ids).to eq([user.id])
        end
      end

      context "when a farther notification exists" do
        before do
          create(:notification, kind: :progress, effort: effort, distance: split_time_total_distance + 1000, bitkey: out_bitkey)
        end

        it "does not send a message to ProgressNotifier" do
          expect(ProgressNotifier).not_to receive(:publish)
          perform_notification
        end

        it "does not create notifications" do
          expect { perform_notification }.not_to(change(Notification, :count))
        end
      end

      context "when a notification having identical distance and bitkey exists" do
        before do
          create(:notification, kind: :progress, effort: effort, distance: split_time_total_distance, bitkey: out_bitkey)
        end

        it "does not send a message to ProgressNotifier" do
          expect(ProgressNotifier).not_to receive(:publish)
          perform_notification
        end

        it "does not create notifications" do
          expect { perform_notification }.not_to(change(Notification, :count))
        end
      end

      context "when a notification having identical distance and an earlier bitkey exists" do
        before do
          create(:notification, kind: :progress, effort: effort, distance: split_time_total_distance, bitkey: in_bitkey)
        end

        it "sends a message to ProgressNotifier" do
          allow(ProgressNotifier).to receive(:publish).and_return(successful_response)
          perform_notification
          expect(ProgressNotifier).to have_received(:publish)
        end

        it "creates notifications" do
          expect { perform_notification }.to change(Notification, :count).by(1)
          notification = Notification.last
          expect(notification.effort_id).to eq(effort.id)
          expect(notification.distance).to eq(notification_split_times.last.total_distance)
          expect(notification.bitkey).to eq(notification_split_times.last.bitkey)
        end
      end
    end

    context "when the effort is notifiable but the notification is not timely" do
      before do
        effort.assign_topic_resource
        effort.save!
        travel_to(notification_split_times.last.absolute_time + 24.hours)
      end

      it "does not send a message to ProgressNotifier" do
        expect(ProgressNotifier).not_to receive(:publish)
        perform_notification
      end

      it "does not create notifications" do
        expect { perform_notification }.not_to(change(Notification, :count))
      end
    end

    context "when the notification is timely but the effort is not notifiable" do
      before do
        effort.update(topic_resource_key: nil)
        travel_to(notification_split_times.last.absolute_time + 1.hour)
      end

      it "does not send a message to ProgressNotifier" do
        expect(ProgressNotifier).not_to receive(:publish)
        perform_notification
      end

      it "does not create notifications" do
        expect { perform_notification }.not_to(change(Notification, :count))
      end
    end
  end
end
