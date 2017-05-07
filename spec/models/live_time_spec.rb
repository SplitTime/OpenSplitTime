require 'rails_helper'

# t.integer  "event_id",        null: false
# t.integer  "lap"
# t.integer  "split_id",        null: false
# t.string   "split_extension"
# t.string   "wave"
# t.integer  "bib_number",      null: false
# t.string   "absolute_time",   null: false
# t.boolean  "with_pacer"
# t.boolean  "stopped_here"
# t.string   "remarks"
# t.integer  "source"
# t.string   "batch"
# t.datetime "recorded_at"

RSpec.describe LiveTime, type: :model do
  describe '#initialize' do
    let(:event) { create(:event, course: course) }
    let(:split) { create(:split, course: course) }
    let(:course) { create(:course) }
    let(:time_string) { '08:00:00' }
    let(:recorded_at) { Time.now }

    it 'is valid when created with an event, split, bib_number, absolute_time, batch, and recorded_at' do
      live_time = LiveTime.new(event: event, split: split, bib_number: 101, absolute_time: time_string, batch: '1', recorded_at: recorded_at)
      expect(live_time).to be_valid
    end

    it 'is invalid when no event is provided' do
      live_time = LiveTime.new(split: split, bib_number: 101, absolute_time: time_string, batch: '1', recorded_at: recorded_at)
      expect(live_time).to be_invalid
    end

    it 'is invalid when no split is provided' do
      live_time = LiveTime.new(event: event, bib_number: 101, absolute_time: time_string, batch: '1', recorded_at: recorded_at)
      expect(live_time).to be_invalid
    end

    it 'is invalid when no bib_number is provided' do
      live_time = LiveTime.new(event: event, split: split, absolute_time: time_string, batch: '1', recorded_at: recorded_at)
      expect(live_time).to be_invalid
    end

    it 'is invalid when no absolute_time is provided' do
      live_time = LiveTime.new(event: event, split: split, bib_number: 101, batch: '1', recorded_at: recorded_at)
      expect(live_time).to be_invalid
    end

    it 'is invalid when no batch is provided' do
      live_time = LiveTime.new(event: event, split: split, bib_number: 101, absolute_time: time_string, recorded_at: recorded_at)
      expect(live_time).to be_invalid
    end

    it 'is invalid when no recorded_at is provided' do
      live_time = LiveTime.new(event: event, split: split, bib_number: 101, absolute_time: time_string, batch: '1')
      expect(live_time).to be_invalid
    end

    it 'saves properly to the database' do
      create(:live_time)
      expect(LiveTime.count).to eq(1)
    end
  end
end
