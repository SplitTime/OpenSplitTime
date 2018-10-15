# frozen_string_literal: true

require 'rails_helper'

# t.bigint "event_group_id", null: false
# t.bigint "split_time_id"
# t.string "split_name", null: false
# t.integer "bitkey", null: false
# t.string "bib_number", null: false
# t.datetime "absolute_time"
# t.string "entered_time"
# t.boolean "with_pacer", default: false
# t.boolean "stopped_here", default: false
# t.string "source", null: false
# t.integer "pulled_by"
# t.datetime "pulled_at"
# t.integer "created_by"
# t.integer "updated_by"


RSpec.describe RawTime, type: :model do
  it_behaves_like 'auditable'
  it_behaves_like 'time_recordable'

  describe '.with_relation_ids' do
    let(:event_1_efforts) { create_list(:effort, 2, event: event_1) }
    let(:event_1) { create(:event, course: course_1, event_group: event_group) }
    let(:event_2_efforts) { create_list(:effort, 2, event: event_2) }
    let(:event_2) { create(:event, course: course_2, event_group: event_group) }
    let(:event_group) { create(:event_group) }
    let(:course_1_split) { create(:split, course: course_1) }
    let(:course_1) { create(:course) }
    let(:course_2_split) { create(:split, course: course_2) }
    let(:course_2) { create(:course) }
    before { event_1.splits << course_1_split }
    before { event_2.splits << course_2_split }

    context 'when bib_numbers and split_names are valid' do
      let!(:raw_time_1) { create(:raw_time, event_group: event_group, bib_number: event_1_efforts.first.bib_number, split_name: course_1_split.base_name) }
      let!(:raw_time_2) { create(:raw_time, event_group: event_group, bib_number: event_1_efforts.second.bib_number, split_name: course_1_split.base_name) }
      let!(:raw_time_3) { create(:raw_time, event_group: event_group, bib_number: event_2_efforts.first.bib_number, split_name: course_2_split.base_name) }
      let!(:raw_time_4) { create(:raw_time, event_group: event_group, bib_number: event_2_efforts.second.bib_number, split_name: course_2_split.base_name) }

      it 'returns raw_times with effort_id, split_id, and event_id attributes loaded' do
        raw_times = RawTime.all.with_relation_ids
        expect(raw_times.size).to eq(4)
        expect(raw_times.map(&:effort_id)).to match_array(Effort.all.ids)
        expect(raw_times.map(&:split_id)).to match_array([course_1_split.id, course_1_split.id, course_2_split.id, course_2_split.id])
        expect(raw_times.map(&:event_id)).to match_array([event_1.id, event_1.id, event_2.id, event_2.id])
      end
    end

    context 'when split_name is valid but bib_number is not valid' do
      let!(:raw_time_1) { create(:raw_time, event_group: event_group, bib_number: '999', split_name: course_1_split.base_name) }

      it 'returns raw_time with effort_id, split_id, and event_id attributes set to nil' do
        raw_times = RawTime.all.with_relation_ids
        expect(raw_times.size).to eq(1)

        raw_time = raw_times.first
        expect(raw_time.effort_id).to be_nil
        expect(raw_time.event_id).to be_nil
        expect(raw_time.split_id).to be_nil
      end
    end

    context 'when bib_number is valid but split_name is not valid' do
      let!(:raw_time_1) { create(:raw_time, event_group: event_group, bib_number: event_1_efforts.first.bib_number, split_name: 'Nonexistent') }

      it 'returns raw_time with effort_id and event_id attributes loaded and split_id set to nil' do
        raw_times = RawTime.all.with_relation_ids
        expect(raw_times.size).to eq(1)

        raw_time = raw_times.first
        expect(raw_time.effort_id).to eq(event_1_efforts.first.id)
        expect(raw_time.event_id).to eq(event_1.id)
        expect(raw_time.split_id).to be_nil
      end
    end

    context 'when bib_number and split_name split_name are both not valid' do
      let!(:raw_time_1) { create(:raw_time, event_group: event_group, bib_number: '999', split_name: 'Nonexistent') }

      it 'returns raw_time with effort_id, split_id, and event_id attributes set to nil' do
        raw_times = RawTime.all.with_relation_ids
        expect(raw_times.size).to eq(1)

        raw_time = raw_times.first
        expect(raw_time.effort_id).to be_nil
        expect(raw_time.event_id).to be_nil
        expect(raw_time.split_id).to be_nil
      end
    end
  end

  describe '#split_time' do
    let(:effort) { create(:effort, event: event) }
    let(:event) { create(:event, course: course, event_group: event_group) }
    let(:event_group) { create(:event_group) }
    let(:split) { create(:split, course: course) }
    let(:course) { create(:course) }
    let(:split_time) { create(:split_time, effort: effort, split: split, bitkey: 1) }
    before { event.splits << split }

    it 'when related split_time is deleted, sets raw_time.split_time to nil' do
      raw_time = create(:raw_time, event_group: event_group, split_name: split.parameterized_base_name, split_time: split_time)
      expect(raw_time.split_time).to eq(split_time)
      SplitTime.last.destroy
      raw_time.reload
      expect(raw_time.split_time).to be_nil
    end
  end

  describe '#data_status' do
    subject { build_stubbed(:raw_time) }

    it 'acts as an ActiveRecord enum' do
      expect(subject.data_status).to be_nil

      subject.assign_attributes(data_status: :bad)
      expect(subject.data_status).to eq('bad')
      expect(subject).to be_bad
      expect(subject).not_to be_good

      subject.assign_attributes(data_status: :good)
      expect(subject.data_status).to eq('good')
      expect(subject).to be_good
      expect(subject).not_to be_bad
    end
  end

  describe '#clean?' do
    subject { build_stubbed(:raw_time, data_status: data_status, split_time_exists: split_time_exists) }
    let(:data_status) { nil }
    let(:split_time_exists) { false }

    context 'when data_status is good and split_time_exists is false' do
      let(:data_status) { :good }

      it 'returns true' do
        expect(subject.clean?).to eq(true)
      end
    end

    context 'when data_status is questionable and split_time_exists is false' do
      let(:data_status) { :questionable }

      it 'returns true' do
        expect(subject.clean?).to eq(true)
      end
    end

    context 'when data_status is bad and split_time_exists is false' do
      let(:data_status) { :bad }

      it 'returns false' do
        expect(subject.clean?).to eq(false)
      end
    end

    context 'when data_status is nil and split_time_exists is false' do
      let(:data_status) { nil }

      it 'returns true' do
        expect(subject.clean?).to eq(true)
      end
    end

    context 'when split_time_exists is true regardless of data_status' do
      let(:data_status) { :good }
      let(:split_time_exists) { true }

      it 'returns false' do
        expect(subject.clean?).to eq(false)
      end
    end
  end
end
