require "rails_helper"

RSpec.describe ImportJob, type: :model do
  subject { build(:import_job, parent: parent, format: format, started_at: started_at) }
  let(:parent) { lotteries(:lottery_without_tickets) }
  let(:format) { :lottery_entrants }
  let(:started_at) { nil }
  let(:test_start_time) { Time.current }

  before { travel_to test_start_time }

  describe "#parent_path" do
    let(:result) { subject.parent_path }

    context "when parent is an organization" do
      let(:parent) { organizations(:hardrock) }

      it "returns an organization historical fact path" do
        expect(result).to eq("/organizations/hardrock/historical_facts")
      end
    end

    context "when parent is a lottery" do
      let(:parent) { lotteries(:lottery_without_tickets) }

      it "returns a lottery setup path" do
        expect(result).to eq("/organizations/hardrock/lotteries/lottery-without-tickets/setup")
      end
    end

    context "when parent is an event group" do
      let(:parent) { event_groups(:hardrock_2016) }

      it "returns an event group setup path" do
        expect(result).to eq("/event_groups/hardrock-2016/entrants")
      end
    end

    context "when parent is an event" do
      let(:parent) { events(:hardrock_2016) }

      context "when the format is event_course_splits" do
        let(:format) { "event_course_splits" }

        it "returns a course setup path" do
          expect(result).to eq("/event_groups/hardrock-2016/events/hardrock-2016/setup_course")
        end

      end

      context "when the format is not course_group_splits" do
        it "returns an event group setup path" do
          expect(result).to eq("/event_groups/hardrock-2016/entrants")
        end
      end
    end
  end

  describe "#set_elapsed_time!" do
    context "when the record has not been persisted" do
      context "when started at time has not been set" do
        it "does not set elapsed time" do
          subject.set_elapsed_time!
          expect(subject.elapsed_time).to be_nil
        end
      end

      context "when started at time has been set" do
        before { subject.assign_attributes(started_at: 30.seconds.ago) }
        it "does not set elapsed time" do
          subject.set_elapsed_time!
          expect(subject.elapsed_time).to be_nil
        end
      end
    end

    context "when the record has been persisted" do
      before { subject.save! }
      context "when started at time has not been set" do
        it "does not set elapsed time" do
          subject.set_elapsed_time!
          expect(subject.elapsed_time).to be_nil
        end
      end

      context "when started at time has been set" do
        before { subject.update(started_at: 30.seconds.ago) }
        it "sets elapsed time to the amount of time that has passed" do
          subject.set_elapsed_time!
          expect(subject.elapsed_time).to eq(30)
        end
      end
    end
  end

  describe "#start!" do
    let(:test_start_time) { "2021-10-31 10:00:00".in_time_zone }
    context "when the import job has not been started" do
      it "sets start time as expected" do
        subject.start!
        expect(subject.started_at).to eq(test_start_time)
      end
    end

    context "when the import job has already been started" do
      let(:started_at) { 2.minutes.ago }
      it "overwrites the existing start time" do
        subject.start!
        expect(subject.started_at).to eq(test_start_time)
      end
    end
  end
end
