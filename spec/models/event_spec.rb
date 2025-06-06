require "rails_helper"

RSpec.describe Event, type: :model do
  include BitkeyDefinitions

  it_behaves_like "auditable"
  it_behaves_like "subscribable"
  it { is_expected.to strip_attribute(:short_name).collapse_spaces }
  it { is_expected.to localize_time_attribute(:scheduled_start_time) }
  it { is_expected.to trim_time_attribute(:scheduled_start_time) }

  describe "initialize" do
    it "is valid when created with a course, organization, event_group, scheduled start time, laps_required" do
      event = build_stubbed(:event)

      expect(event.course_id).to be_present
      expect(event.event_group_id).to be_present
      expect(event.scheduled_start_time).to be_present
      expect(event.laps_required).to be_present
      expect(event).to be_valid
    end

    it "is invalid without a course" do
      event = build_stubbed(:event, course: nil)
      expect(event).not_to be_valid
      expect(event.errors[:course_id]).to include("can't be blank")
    end

    it "is invalid without an event_group" do
      event = build_stubbed(:event, event_group: nil)
      expect(event).not_to be_valid
      expect(event.errors[:event_group]).to include("can't be blank")
    end

    it "is invalid without a scheduled start time" do
      event = build_stubbed(:event, scheduled_start_time: nil)
      expect(event).not_to be_valid
      expect(event.errors[:scheduled_start_time]).to include("can't be blank")
    end

    it "is invalid without a laps_required" do
      event = build_stubbed(:event, laps_required: nil)
      expect(event).not_to be_valid
      expect(event.errors[:laps_required]).to include("can't be blank")
    end

    it "is invalid if any splits do not reconcile with the course" do
      course = build_stubbed(:course)
      other_course = build_stubbed(:course)
      split_1 = build_stubbed(:split, course: course)
      split_2 = build_stubbed(:split, course: other_course)
      splits = [split_1, split_2]
      event = build_stubbed(:event, course: course, splits: splits)
      expect(event).to be_invalid
      expect(event.errors[:course_id]).to include(/does not reconcile with one or more splits/)
    end

    it "does not permit duplicate short_names within an event group" do
      existing_event = events(:sum_55k)
      event = build_stubbed(:event, event_group: existing_event.event_group, short_name: existing_event.short_name)
      expect(event).not_to be_valid
      expect(event.errors[:short_name]).to include("has already been taken")
    end

    context "when bib numbers are duplicated within the same event_group" do
      let(:event) { events(:rufa_2016) }
      let(:event_group) { event_groups(:rufa_2017) }

      before { event.efforts.first.update(bib_number: event_group.efforts.first.bib_number) }

      it "marks the event group as invalid" do
        expect(event).to be_valid

        # Although the event does not update, for some reason the event is not marked as invalid,
        # so instead test using the save response.
        response = event.update(event_group: event_group)
        expect(response).to eq(false)
        expect(event.errors.full_messages).to include(/Bib number \d+ is duplicated within the event group/)
      end
    end

    context "for split location validations" do
      let(:event_1) { events(:sum_100k) }
      let(:event_2) { events(:sum_55k) }
      let(:event_group) { event_1.event_group }
      let(:course_1) { event_1.course }
      let(:course_1_split_1) { course_1.ordered_splits.first }
      let(:course_1_split_2) { course_1.ordered_splits.last }
      let(:course_2) { event_2.course }
      let(:course_2_split_1) { course_2.ordered_splits.first }
      let(:course_2_split_2) { course_2.ordered_splits.last }

      before do
        new_event_group = create(:event_group, organization: event_group.organization)
        event_2.update(event_group: new_event_group)
      end

      context "when split names are duplicated with matching locations within the same event_group" do
        it "is valid" do
          expect(course_1_split_1.base_name).to eq(course_2_split_1.base_name)
          expect(course_1_split_1.latitude).to eq(course_2_split_1.latitude)
          expect(course_1_split_1.longitude).to eq(course_2_split_1.longitude)
          expect(event_1.errors).to be_empty

          response = event_2.update(event_group: event_group)

          expect(response).to eq(true)
          expect(event_2.errors).to be_empty
        end
      end

      context "when split names are duplicated with non-matching locations within the same event_group" do
        before { course_2_split_1.update(longitude: course_1_split_1.longitude + 1) }

        it "is invalid" do
          expect(course_1_split_1.base_name).to eq(course_2_split_1.base_name)
          expect(course_1_split_1.latitude).to eq(course_2_split_1.latitude)
          expect(course_1_split_1.longitude).not_to eq(course_2_split_1.longitude)
          expect(event_1.errors).to be_empty

          response = event_2.update(event_group: event_group)

          expect(response).to eq(false)
          expect(event_2.errors.full_messages).to include(/Location Start is incompatible within the event group/)
        end
      end
    end
  end

  describe "methods that produce lap_splits and time_points" do
    let(:event) { build_stubbed(:event, laps_required: 2) }
    let(:start_split) { build_stubbed(:split, :start, id: 111) }
    let(:intermediate_split1) { build_stubbed(:split, id: 102) }
    let(:intermediate_split2) { build_stubbed(:split, id: 103) }
    let(:finish_split) { build_stubbed(:split, :finish, id: 112) }
    let(:splits) { [start_split, intermediate_split1, intermediate_split2, finish_split] }

    describe "#required_lap_splits" do
      it "returns an empty array when laps_required is zero" do
        test_event = event
        test_event.laps_required = 0
        ordered_splits = splits
        allow_any_instance_of(Event).to receive(:ordered_splits).and_return(ordered_splits)
        required_lap_splits = test_event.required_lap_splits
        expect(required_lap_splits).to eq([])
      end

      it "returns an array whose size is equal to laps_required * number of splits" do
        test_event = event
        ordered_splits = splits
        allow_any_instance_of(Event).to receive(:ordered_splits).and_return(ordered_splits)
        required_lap_splits = test_event.required_lap_splits
        expect(required_lap_splits.size).to eq(8)
      end

      it "returns an array of LapSplit objects ordered by lap, split distance, and bitkey" do
        test_event = event
        ordered_splits = splits
        allow_any_instance_of(Event).to receive(:ordered_splits).and_return(ordered_splits)
        required_lap_splits = test_event.required_lap_splits
        expect(required_lap_splits.size).to eq(8)
        expect(required_lap_splits.map(&:lap)).to eq([1] * 4 + [2] * 4)
        expect(required_lap_splits.map(&:split).map(&:id)).to eq([111, 102, 103, 112] * 2)
      end
    end

    describe "#required_time_points" do
      it "returns an empty array when laps_required is zero" do
        test_event = event
        test_event.laps_required = 0
        ordered_splits = splits
        allow_any_instance_of(Event).to receive(:ordered_splits).and_return(ordered_splits)
        required_time_points = test_event.required_time_points
        expect(required_time_points).to eq([])
      end

      it "returns an array whose size is equal to laps_required * number of sub_splits" do
        test_event = event
        ordered_splits = splits
        allow_any_instance_of(Event).to receive(:ordered_splits).and_return(ordered_splits)
        required_time_points = test_event.required_time_points
        expect(required_time_points.size).to eq(12)
      end

      it "returns an array of TimePoint objects ordered by lap, split distance, and bitkey" do
        test_event = event
        ordered_splits = splits
        allow_any_instance_of(Event).to receive(:ordered_splits).and_return(ordered_splits)
        required_time_points = test_event.required_time_points
        expect(required_time_points.map(&:lap)).to eq([1] * 6 + [2] * 6)
        expect(required_time_points.map(&:split_id)).to eq([111, 102, 102, 103, 103, 112] * 2)
        expect(required_time_points.map(&:bitkey)).to eq([1, 1, 64, 1, 64, 1] * 2)
      end
    end
  end

  describe "#multiple_laps?" do
    it "returns false if the event requires exactly one lap" do
      event = build_stubbed(:event, laps_required: 1)
      expect(event.multiple_laps?).to be_falsey
    end

    it "returns true if the event requires more than one lap" do
      event = build_stubbed(:event, laps_required: 2)
      expect(event.multiple_laps?).to be_truthy
    end

    it "returns true if the event requires zero (i.e. unlimited) laps" do
      event = build_stubbed(:event, laps_required: 0)
      expect(event.multiple_laps?).to be_truthy
    end
  end

  describe "#maximum_laps" do
    it "returns laps_required when laps_required is 1" do
      event = build_stubbed(:event, laps_required: 1)
      expect(event.maximum_laps).to eq(1)
    end

    it "returns laps_required when laps_required is greater than 1" do
      event = build_stubbed(:event, laps_required: 3)
      expect(event.maximum_laps).to eq(3)
    end

    it "returns nil when laps_required is 0" do
      event = build_stubbed(:event, laps_required: 0)
      expect(event.maximum_laps).to eq(nil)
    end
  end

  describe "#scheduled_start_time_local" do
    context "when the event_group specifies a valid home_time_zone" do
      let(:event) { build_stubbed(:event, event_group: event_group) }
      let(:event_group) { build(:event_group, home_time_zone: "Eastern Time (US & Canada)") }

      it "returns the start_time in the time zone specified by event.home_time_zone" do
        event.scheduled_start_time = DateTime.parse("2017-07-01T06:00+00:00")
        expect(event.scheduled_start_time_local.time_zone.name).to eq(event.home_time_zone)
        expect(event.scheduled_start_time_local.to_s).to eq("2017-07-01 02:00:00 -0400")
      end

      it "properly senses daylight savings time where applicable" do
        event.scheduled_start_time = DateTime.parse("2017-12-15T06:00+00:00")
        expect(event.scheduled_start_time_local.time_zone.name).to eq(event.home_time_zone)
        expect(event.scheduled_start_time_local.to_s).to eq("2017-12-15 01:00:00 -0500")
      end
    end

    context "when the event home_time_zone is nil" do
      let(:event) { build_stubbed(:event, scheduled_start_time: DateTime.parse("2017-07-01T06:00+00:00"), event_group: event_group) }
      let(:event_group) { build(:event_group, home_time_zone: nil) }

      it "returns nil" do
        expect(event.scheduled_start_time_local).to be_nil
      end
    end

    context "when the event start_time is nil" do
      let(:event) { build_stubbed(:event, scheduled_start_time: nil, event_group: event_group) }
      let(:event_group) { build(:event_group, home_time_zone: "Eastern Time (US & Canada)") }

      it "returns nil" do
        expect(event.scheduled_start_time_local).to be_nil
      end
    end
  end

  describe "#scheduled_start_time_local=" do
    let(:event) { build_stubbed(:event, event_group: event_group) }

    context "when home_time_zone exists" do
      let(:event_group) { build(:event_group, home_time_zone: "Eastern Time (US & Canada)") }

      it "converts the string based on the specified home_time_zone" do
        event.scheduled_start_time_local = "07/01/2017 06:00:00"
        start_time = event.scheduled_start_time.in_time_zone("GMT")
        expect(start_time).to eq("2017-07-01 10:00:00 -0000")
      end

      it "works properly with a 24-hour time" do
        event.scheduled_start_time_local = "07/01/2017 16:00:00"
        start_time = event.scheduled_start_time.in_time_zone("GMT")
        expect(start_time).to eq("2017-07-01 20:00:00 -0000")
      end

      it "works properly with AM/PM time" do
        event.scheduled_start_time_local = "07/01/2017 04:00:00 PM"
        start_time = event.scheduled_start_time.in_time_zone("GMT")
        expect(start_time).to eq("2017-07-01 20:00:00 -0000")
      end

      it "works properly with date formatted in yyyy-mm-dd style" do
        event.scheduled_start_time_local = "2017-07-01 16:00:00"
        start_time = event.scheduled_start_time.in_time_zone("GMT")
        expect(start_time).to eq("2017-07-01 20:00:00 -0000")
      end

      it "works properly regardless of daylight savings time" do
        event.scheduled_start_time_local = "2017-12-15 16:00:00"
        start_time = event.scheduled_start_time.in_time_zone("GMT")
        expect(start_time).to eq("2017-12-15 21:00:00 -0000")
      end
    end

    context "when home_time_zone does not exist" do
      let(:event_group) { build(:event_group, home_time_zone: nil) }

      it "raises an error" do
        expect { event.scheduled_start_time_local = "2017-07-01 06:00:00" }
            .to raise_error(/scheduled_start_time_local cannot be set without a valid home_time_zone/)
      end
    end
  end

  describe "#events_within_group" do
    subject { create(:event, event_group: event_group_1) }
    let!(:event_group_1) { create(:event_group) }
    let!(:event_group_2) { create(:event_group) }
    let!(:event_same_group) { create(:event, :with_short_name, event_group: event_group_1) }
    let!(:event_different_group) { create(:event, :with_short_name, event_group: event_group_2) }

    it "returns the event and other members of the group as an array" do
      subject.reload
      expect(subject.events_within_group).to include(subject)
      expect(subject.events_within_group).to include(event_same_group)
      expect(subject.events_within_group).not_to include(event_different_group)
    end
  end

  describe "#simple?" do
    subject { build_stubbed(:event, splits: splits, laps_required: laps_required) }

    context "when the event has only a start and finish split and only one lap" do
      let(:splits) { build_stubbed_list(:split, 2) }
      let(:laps_required) { 1 }

      it "returns true" do
        expect(subject.simple?).to eq(true)
      end
    end

    context "when the event has only a start and finish split but multiple laps" do
      let(:splits) { build_stubbed_list(:split, 2) }
      let(:laps_required) { 0 }

      it "returns false" do
        expect(subject.simple?).to eq(false)
      end
    end

    context "when the event has more than two splits and only one lap" do
      let(:splits) { build_stubbed_list(:split, 3) }
      let(:laps_required) { 1 }

      it "returns false" do
        expect(subject.simple?).to eq(false)
      end
    end
  end

  describe "#guaranteed_short_name" do
    context "when a short_name exists for the event" do
      let(:event) { build_stubbed(:event, short_name: "Test Short Name") }

      it "returns the short name" do
        expect(event.guaranteed_short_name).to eq(event.short_name)
      end
    end

    context "when no short_name exists for the event" do
      let(:event) { build_stubbed(:event, short_name: nil) }

      it "returns the event name" do
        expect(event.guaranteed_short_name).to eq(event.name)
      end
    end
  end

  describe "methods from the SplitMethods module" do
    let(:event) { build_stubbed(:event, splits: splits) }
    let(:start_split) { build_stubbed(:split, :start) }
    let(:intermediate_split_1) { build_stubbed(:split, distance_from_start: 500) }
    let(:intermediate_split_2) { build_stubbed(:split, distance_from_start: 1500) }
    let(:intermediate_split_3) { build_stubbed(:split, distance_from_start: 2800) }
    let(:finish_split) { build_stubbed(:split, :finish, distance_from_start: 4000) }
    let(:splits) { [start_split, intermediate_split_1, intermediate_split_2, intermediate_split_3, finish_split].shuffle }

    describe "#ordered_splits" do
      it "returns all splits sorted by distance_from_start" do
        expect(event.ordered_splits.map(&:distance_from_start)).to eq(splits.map(&:distance_from_start).sort)
      end
    end

    describe "#ordered_split_ids" do
      it "returns all split ids sorted by distance_from_start" do
        expect(event.ordered_split_ids).to eq(splits.sort_by(&:distance_from_start).map(&:id))
      end
    end

    describe "#ordered_splits_without_start" do
      it "returns all splits sorted by distance_from_start without the start split" do
        expect(event.ordered_splits_without_start.map(&:distance_from_start)).to eq((splits - [start_split]).map(&:distance_from_start).sort)
      end
    end

    describe "#ordered_splits_without_finish" do
      it "returns all splits sorted by distance_from_start without the finish split" do
        expect(event.ordered_splits_without_finish.map(&:distance_from_start)).to eq((splits - [finish_split]).map(&:distance_from_start).sort)
      end
    end

    describe "#ordered_splits_without_finish" do
      it "returns all splits sorted by distance_from_start without the finish split" do
        expect(event.ordered_splits_without_finish.map(&:distance_from_start)).to eq((splits - [finish_split]).map(&:distance_from_start).sort)
      end
    end

    describe "#start_split" do
      it "returns the start split" do
        expect(event.start_split).to eq(start_split)
      end
    end

    describe "#finish_split" do
      it "returns the finish split" do
        expect(event.finish_split).to eq(finish_split)
      end
    end

    describe "#sub_splits" do
      it "returns an array of ordered sub_splits" do
        expect(event.sub_splits).to eq([SubSplit.new(start_split.id, in_bitkey),
                                        SubSplit.new(intermediate_split_1.id, in_bitkey), SubSplit.new(intermediate_split_1.id, out_bitkey),
                                        SubSplit.new(intermediate_split_2.id, in_bitkey), SubSplit.new(intermediate_split_2.id, out_bitkey),
                                        SubSplit.new(intermediate_split_3.id, in_bitkey), SubSplit.new(intermediate_split_3.id, out_bitkey),
                                        SubSplit.new(finish_split.id, in_bitkey)])
      end
    end
  end
end
