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
