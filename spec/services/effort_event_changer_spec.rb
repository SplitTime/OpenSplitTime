require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe EffortEventChanger do
  let(:effort) { create(:effort, event: old_event) }
  let(:old_event) { create(:event, course: old_course, start_time: '2017-07-01 06:00:00') }
  let(:old_course) { create(:course_with_standard_splits, splits_count: 3) }

  describe '#initialization' do
    let(:effort) { build_stubbed(:effort) }
    let(:event) { build_stubbed(:event) }

    it 'initializes when provided with an effort and a new event_id' do
      expect { EffortEventChanger.new(effort: effort, event: event) }
          .not_to raise_error
    end

    it 'raises an error if no effort is provided' do
      expect { EffortEventChanger.new(effort: nil, event: event) }
          .to raise_error(/must include effort/)
    end

    it 'raises an error if no model is provided' do
      expect { EffortEventChanger.new(effort: effort, event: nil) }
          .to raise_error(/must include event/)
    end
  end

  describe '#assign_event' do
    context 'when the new event has the same splits as the old' do
      let!(:new_event) { create(:event, course: old_course, start_time: '2017-07-01 08:00:00') }

      before do
        old_event.splits << old_course.splits
        new_event.splits << old_course.splits
        create_split_times_for_effort
      end

      it 'updates the effort event_id to the id of the provided event' do
        expect(effort.event_id).not_to eq(new_event.id)
        changer = EffortEventChanger.new(effort: effort, event: new_event)
        changer.assign_event
        expect(effort.event_id).to eq(new_event.id)
      end

      it 'does not change the split_id of any effort split_times' do
        split_times = effort.split_times
        expect(split_times.size).to eq(4)
        changer = EffortEventChanger.new(effort: effort, event: new_event)
        changer.assign_event
        expect(split_times.none?(&:changed?)).to be_truthy
      end

      it 'updates the effort start offset such that the absolute effort start_time does not change' do
        existing_start_time = effort.start_time
        puts existing_start_time
        changer = EffortEventChanger.new(effort: effort, event: new_event)
        changer.assign_event
        reloaded_effort = Effort.find(effort.id)
        expect(reloaded_effort.start_time).to eq(existing_start_time)
      end
    end

    context 'when the new event has different splits from the old' do
      let(:new_event) { create(:event, course: new_course) }
      let(:new_course) { create(:course, splits: new_splits) }
      let(:new_split_1) { create(:start_split) }
      let(:new_split_2) { create(:split, distance_from_start: old_course.ordered_splits.second.distance_from_start) }
      let(:new_split_3) { create(:split, distance_from_start: old_course.ordered_splits.third.distance_from_start) }
      let(:new_split_4) { create(:split, distance_from_start: new_split_3.distance_from_start + 10000) }
      let(:new_splits) { [new_split_1, new_split_2, new_split_3, new_split_4] }

      before do
        FactoryGirl.reload
        old_event.splits << old_course.splits
        new_event.splits << new_course.splits
        create_split_times_for_effort
      end

      it 'updates the effort event_id to the id of the provided event' do
        expect(effort.event_id).not_to eq(new_event.id)
        changer = EffortEventChanger.new(effort: effort, event: new_event)
        changer.assign_event
        expect(effort.event_id).to eq(new_event.id)
      end

      it 'changes the split_ids of effort split_times to the corresponding split_ids of the new event' do
        time_points = new_event.required_time_points.first(effort.split_times.size)
        expect(effort.split_times.map(&:time_point)).not_to eq(time_points)
        changer = EffortEventChanger.new(effort: effort, event: new_event)
        changer.assign_event
        effort.reload
        expect(effort.split_times.map(&:time_point)).to eq(time_points)
      end

      it 'raises an error if distances do not coincide' do
        split = new_event.ordered_splits.second
        split.update(distance_from_start: split.distance_from_start - 1)
        new_event.reload
        expect { EffortEventChanger.new(effort: effort, event: new_event) }
            .to raise_error(/distances do not coincide/)
      end

      it 'raises an error if sub_splits do not coincide' do
        split = new_event.ordered_splits.second
        split.update(sub_split_bitmap: 1)
        new_event.reload
        expect { EffortEventChanger.new(effort: effort, event: new_event) }
            .to raise_error(/sub splits do not coincide/)
      end

      it 'raises an error if laps are out of range' do
        split_time = effort.ordered_split_times.last
        split_time.update(lap: 2)
        expect { EffortEventChanger.new(effort: effort, event: new_event) }
            .to raise_error(/laps exceed maximum required/)
      end
    end

    def create_split_times_for_effort
      time_points = old_event.required_time_points
      time_points.each_with_index do |time_point, i|
        create(:split_time, time_point: time_point, effort: effort, time_from_start: i * 1000)
      end
    end
  end
end
