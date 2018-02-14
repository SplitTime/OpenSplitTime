require 'rails_helper'

RSpec.describe Interactors::ChangeEventCourse do
  subject { Interactors::ChangeEventCourse.new(event: event, new_course: new_course) }

  describe '#initialization' do
    let(:event) { build_stubbed(:event) }
    let(:new_course) { build_stubbed(:course) }

    it 'initializes when provided with an event and a new course_id' do
      expect { subject }.not_to raise_error
    end

    context 'if no event is provided' do
      let(:event) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error(/must include event/)
      end
    end

    context 'if no new_course is provided' do
      let(:new_course) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error(/must include new_course/)
      end
    end
  end

  describe '#perform!' do
    let(:event) { create(:event, course: old_course) }
    let!(:old_course) { create(:course, splits: old_splits) }
    let(:old_split_1) { create(:start_split) }
    let(:old_split_2) { create(:split, distance_from_start: 10000) }
    let(:old_split_3) { create(:split, distance_from_start: 20000) }
    let(:old_splits) { [old_split_1, old_split_2, old_split_3] }
    let!(:efforts) { create_list(:effort, 2, event: event) }

    context 'when the new course has splits with the same distances as the old' do
      let(:new_course) { create(:course, splits: new_splits) }
      let(:new_split_1) { create(:start_split) }
      let(:new_split_2) { create(:split, distance_from_start: old_course.ordered_splits.second.distance_from_start) }
      let(:new_split_3) { create(:split, distance_from_start: old_course.ordered_splits.third.distance_from_start) }
      let(:new_split_4) { create(:split, distance_from_start: new_split_3.distance_from_start + 10000) }
      let(:new_splits) { [new_split_1, new_split_2, new_split_3, new_split_4] }

      before do
        FactoryBot.reload
        old_course.reload
        new_course.reload
        event.splits << old_course.splits
        create_split_times_for_event
      end

      it 'updates the event course_id to the id of the provided course' do
        expect(event.course_id).not_to eq(new_course.id)
        response = subject.perform!
        expect(event.course_id).to eq(new_course.id)
        expect(response).to be_successful
        expect(response.message).to match(/was changed to/)
      end

      it 'changes the split_ids of event split_times to the corresponding split_ids of the new course' do
        sub_splits = new_course.sub_splits.first(efforts.first.split_times.size)
        efforts.each do |effort|
          effort.reload
          expect(effort.split_times.map(&:sub_split)).not_to match_array(sub_splits)
        end
        subject.perform!
        efforts.each do |effort|
          effort.reload
          expect(effort.split_times.map(&:sub_split)).to match_array(sub_splits)
        end
      end

      it 'returns an unsuccessful response with errors if distances do not coincide' do
        split = new_course.ordered_splits.second
        split.update(distance_from_start: split.distance_from_start - 1)
        new_course.reload
        response = subject.perform!
        expect(response).not_to be_successful
        expect(response.errors.first[:detail][:messages]).to include(/distances do not coincide/)
      end

      it 'raises an error if sub_splits do not coincide' do
        split = new_course.ordered_splits.second
        split.update(sub_split_bitmap: 1)
        new_course.reload
        response = subject.perform!
        expect(response).not_to be_successful
        expect(response.errors.first[:detail][:messages]).to include(/sub splits do not coincide/)
      end
    end

    def create_split_times_for_event
      time_points = event.required_time_points
      efforts.each do |effort|
        time_points.each_with_index do |time_point, i|
          create(:split_time, time_point: time_point, effort: effort, time_from_start: i * 1000)
        end
      end
    end
  end
end
