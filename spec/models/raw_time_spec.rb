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
  it_behaves_like 'live_raw_times_methods'
  
  describe '.with_split_ids' do
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

    let!(:raw_time_1) { create(:raw_time, event_group: event_group, bib_number: event_1_efforts.first.bib_number, split_name: course_1_split.base_name) }
    let!(:raw_time_2) { create(:raw_time, event_group: event_group, bib_number: event_1_efforts.second.bib_number, split_name: course_1_split.base_name) }
    let!(:raw_time_3) { create(:raw_time, event_group: event_group, bib_number: event_2_efforts.first.bib_number, split_name: course_2_split.base_name) }
    let!(:raw_time_4) { create(:raw_time, event_group: event_group, bib_number: event_2_efforts.second.bib_number, split_name: course_2_split.base_name) }

    it 'returns raw_times with effort_id and split_id attributes loaded' do
      raw_times = RawTime.all.with_effort_split_ids
      expect(raw_times.size).to eq(4)
      expect(raw_times.map(&:effort_id)).to match_array(Effort.all.ids)
      expect(raw_times.map(&:split_id)).to match_array([course_1_split.id, course_1_split.id, course_2_split.id, course_2_split.id])
    end
  end

  describe '#split_time' do
    let(:effort) { create(:effort, event: event) }
    let(:event) { create(:event, course: course, event_group: event_group) }
    let(:event_group) { create(:event_group) }
    let(:split) { create(:split, course: course) }
    let(:course) { create(:course) }
    let(:split_time) { create(:split_time, effort: effort, split: split) }
    before { event.splits << split }

    it 'when related split_time is deleted, sets raw_time.split_time to nil' do
      raw_time = create(:raw_time, event_group: event_group, split_name: split.parameterized_base_name, split_time: split_time)
      expect(raw_time.split_time).to eq(split_time)
      SplitTime.last.destroy
      raw_time.reload
      expect(raw_time.split_time).to be_nil
    end
  end
end
