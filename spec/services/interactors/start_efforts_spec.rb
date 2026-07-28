require "rails_helper"

RSpec.describe Interactors::StartEfforts do
  include BitkeyDefinitions

  describe ".perform!" do
    subject { described_class.new(efforts: subject_efforts, start_time: start_time) }

    let(:home_time_zone) { subject_efforts.first.home_time_zone }

    context "when one effort fails to save mid-batch" do
      let(:subject_efforts) { [efforts(:sum_55k_not_started), efforts(:sum_100k_un_started)] }
      let(:start_time) { nil }

      before do
        # The event must be updated first; effort callbacks memoize event_start_time
        subject_efforts.second.event.update_column(:scheduled_start_time, nil)
        subject_efforts.first.update(scheduled_start_time: "2017-09-23 07:00:00".in_time_zone(home_time_zone))
        subject_efforts.second.update(scheduled_start_time: nil)
      end

      it "rolls back all created split times and returns a failure response" do
        response = nil
        expect { response = subject.perform! }.not_to change(SplitTime, :count)

        expect(response).not_to be_successful
        expect(response.message).to eq("No efforts were started")
      end

      it "does not touch efforts or events" do
        expect { subject.perform! }
          .to not_change { subject_efforts.map { |effort| effort.reload.updated_at } }
          .and(not_change { subject_efforts.map { |effort| effort.event.reload.updated_at } })
      end

      it "does not broadcast or enqueue notifications" do
        subject_efforts.each { |effort| expect(effort).not_to receive(:broadcast_update) }
        expect(NotifyEventUpdateJob).not_to receive(:perform_later)

        subject.perform!
      end
    end

    context "when all provided efforts are valid" do
      context "when no efforts have a starting split time" do
        let(:subject_efforts) { [efforts(:sum_55k_not_started), efforts(:sum_100k_un_started)] }

        context "when start_time is provided as a string with no time zone" do
          let(:start_time) { "2017-09-23 08:00:00" }

          it "creates start split_times for each effort and returns a successful response" do
            expect(subject_efforts.map(&:starting_split_time)).to all be_nil
            response = subject.perform!

            expect(response).to be_successful
            expect(response.message).to eq("Started 2 efforts at 09/23/2017 08:00:00")

            subject_efforts.each(&:reload)
            split_times = subject_efforts.map(&:starting_split_time)
            expect(split_times).to all be_present
            expect(split_times.map(&:absolute_time)).to all eq(start_time.in_time_zone(home_time_zone))
          end
        end

        context "when start_time is a valid date string with time zone information" do
          let(:start_time) { "2017-09-23 08:00:00 EDT" }

          it "creates start split_times for each effort" do
            subject.perform!

            subject_efforts.each(&:reload)
            split_times = subject_efforts.map(&:starting_split_time)
            expect(split_times.map(&:absolute_time)).to all eq("2017-09-23 08:00:00".in_time_zone("Eastern Time (US & Canada)"))
          end
        end

        context "when start_time is provided as a datetime object" do
          let(:start_time) { "2017-09-23 08:00:00".in_time_zone(home_time_zone) }

          it "creates start split_times for each effort" do
            subject.perform!

            subject_efforts.each(&:reload)
            split_times = subject_efforts.map(&:starting_split_time)
            expect(split_times.map(&:absolute_time)).to all eq(start_time.in_time_zone(home_time_zone))
          end
        end

        context "when start_time is not provided" do
          let(:start_time) { nil }

          before do
            subject_efforts.first.update(scheduled_start_time: "2017-09-23 11:00:00".in_time_zone(home_time_zone))
            subject_efforts.second.update(scheduled_start_time: nil)
          end

          it "creates start split_times using scheduled_start_time when available or event_start_time otherwise" do
            subject.perform!

            subject_efforts.each(&:reload)
            split_times = subject_efforts.map(&:starting_split_time)
            expect(split_times.first.absolute_time).to eq(subject_efforts.first.scheduled_start_time)
            expect(split_times.second.absolute_time).to eq(subject_efforts.second.event_start_time)
          end
        end

        context "when start_time is an empty string" do
          let(:start_time) { "" }

          before do
            subject_efforts.first.update(scheduled_start_time: "2017-09-23 11:00:00".in_time_zone(home_time_zone))
            subject_efforts.second.update(scheduled_start_time: nil)
          end

          it "creates start split_times using scheduled_start_time when available or event_start_time otherwise" do
            response = subject.perform!

            expect(response).to be_successful

            subject_efforts.each(&:reload)
            split_times = subject_efforts.map(&:starting_split_time)
            expect(split_times.first.absolute_time).to eq(subject_efforts.first.scheduled_start_time)
            expect(split_times.second.absolute_time).to eq(subject_efforts.second.event_start_time)
          end
        end

        context "when start_time is provided but is not a parsable datetime" do
          let(:start_time) { "hello" }

          it "creates start split_times using scheduled_start_time when available or event_start_time otherwise" do
            response = subject.perform!

            expect(response).not_to be_successful
            subject_efforts.each(&:reload)
            split_times = subject_efforts.map(&:starting_split_time)
            expect(split_times).to all be_nil
          end
        end
      end

      context "when one effort has an existing starting split time" do
        let(:subject_efforts) { [efforts(:sum_55k_not_started), efforts(:sum_100k_progress_cascade)] }
        let(:start_time) { "2017-09-23 08:00:00" }

        it "creates or updates starting split times as needed" do
          expect { subject.perform! }.to change(SplitTime, :count).by(1)

          subject_efforts.each(&:reload)
          split_times = subject_efforts.map(&:starting_split_time)
          expect(split_times).to all be_present
          expect(split_times.first.absolute_time).to eq(start_time.in_time_zone(home_time_zone))
          expect(split_times.second.absolute_time).to eq(start_time.in_time_zone(home_time_zone))
        end

        it "returns a successful response" do
          expect(subject.perform!).to be_successful
        end

        it "recalculates elapsed_seconds for all of the effort's split times" do
          subject.perform!

          effort = subject_efforts.second.reload
          start_absolute_time = effort.starting_split_time.absolute_time
          effort.split_times.each do |split_time|
            expect(split_time.elapsed_seconds).to eq(split_time.absolute_time - start_absolute_time)
          end
        end

        it "rebuilds effort segments from the new start time" do
          subject.perform!

          effort = subject_efforts.second.reload
          start_split_id = effort.starting_split_time.split_id
          start_segments = EffortSegment.where(effort_id: effort.id, begin_split_id: start_split_id)
          expect(start_segments).to be_present
          expect(start_segments.map(&:begin_time)).to all eq(start_time.in_time_zone(home_time_zone))
        end
      end

      context "with respect to derived data and touches" do
        let(:subject_efforts) { [efforts(:sum_55k_not_started), efforts(:sum_100k_un_started)] }
        let(:start_time) { "2017-09-23 08:00:00" }

        it "sets elapsed_seconds on the new starting split times" do
          subject.perform!

          split_times = subject_efforts.map { |effort| effort.reload.starting_split_time }
          expect(split_times.map(&:elapsed_seconds)).to all eq(0)
        end

        it "sets performance data on the efforts" do
          expect(subject_efforts.map(&:started)).to all be(false)
          subject.perform!

          subject_efforts.each(&:reload)
          expect(subject_efforts.map(&:started)).to all be(true)
        end

        it "touches the efforts and their events" do
          expect { subject.perform! }
            .to change { subject_efforts.map { |effort| effort.reload.updated_at } }
            .and(change { subject_efforts.map { |effort| effort.event.reload.updated_at } })
        end

        context "when an event has a topic resource key" do
          let(:subscribed_event) { subject_efforts.first.event }

          before { subscribed_event.update_column(:topic_resource_key, "test-resource-key") }

          it "enqueues a notification job for that event only" do
            expect(NotifyEventUpdateJob).to receive(:perform_later).with(subscribed_event.id).once
            subject.perform!
          end
        end

        context "when the efforts were already started at the given time" do
          before { described_class.perform!(efforts: subject_efforts, start_time: start_time) }

          it "returns a successful response but does not touch efforts or events" do
            expect(NotifyEventUpdateJob).not_to receive(:perform_later)
            response = nil
            expect { response = subject.perform! }
              .to not_change { subject_efforts.map { |effort| effort.reload.updated_at } }
              .and(not_change { subject_efforts.map { |effort| effort.event.reload.updated_at } })
            expect(response).to be_successful
          end
        end
      end
    end
  end
end
