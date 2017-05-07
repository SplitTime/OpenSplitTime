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
# t.integer  "split_time_id"

RSpec.describe LiveTime, type: :model do
  describe '#initialize' do
    let(:event) { create(:event, course: course) }
    let(:split) { create(:split, course: course) }
    let(:course) { create(:course) }
    let(:time_string) { '08:00:00' }

    it 'is valid when created with an event, split, bib_number, and absolute_time' do
      live_time = LiveTime.new(event: event, split: split, bib_number: 101, absolute_time: time_string)
      expect(live_time).to be_valid
    end

    it 'is invalid when no event is provided' do
      live_time = LiveTime.new(split: split, bib_number: 101, absolute_time: time_string)
      expect(live_time).to be_invalid
      expect(live_time.errors.full_messages).to include("Event can't be blank")
    end

    it 'is invalid when no split is provided' do
      live_time = LiveTime.new(event: event, bib_number: 101, absolute_time: time_string)
      expect(live_time).to be_invalid
      expect(live_time.errors.full_messages).to include("Split can't be blank")
    end

    it 'is invalid when no bib_number is provided' do
      live_time = LiveTime.new(event: event, split: split, absolute_time: time_string)
      expect(live_time).to be_invalid
      expect(live_time.errors.full_messages).to include("Bib number can't be blank")
    end

    it 'is invalid when no absolute_time is provided' do
      live_time = LiveTime.new(event: event, split: split, bib_number: 101)
      expect(live_time).to be_invalid
      expect(live_time.errors.full_messages).to include("Absolute time can't be blank")
    end

    it 'is invalid when the event.course is not the same as the split.course' do
      new_split = create(:split)
      live_time = LiveTime.new(event: event, split: new_split, bib_number: 101, absolute_time: time_string)
      expect(live_time).to be_invalid
      expect(live_time.errors.full_messages).to include('Effort the event.course_id does not resolve with the split.course_id')
    end

    it 'saves a valid record to the database' do
      create(:live_time, event: event, split: split)
      expect(LiveTime.count).to eq(1)
    end
  end

  describe '#event_slug' do
    let!(:event) { create(:event, slug: 'test-event') }

    it 'returns the slug of the associated event' do
      live_time = LiveTime.new(event: event)
      expect(live_time.event_slug).to eq(event.slug)
    end
  end

  describe '#event_slug=' do
    let!(:event) { create(:event, slug: 'test-event') }
    let(:live_time) { LiveTime.new }

    it 'finds the event having a slug equal to the provided param and sets event_id' do
      live_time.event_slug = 'test-event'
      expect(live_time.event).to eq(event)
    end

    it 'sets the event to nil if the slug is not found' do
      live_time.event_slug = 'nonexistent-event'
      expect(live_time.event_id).to be_nil
    end
  end

  describe '#split_slug' do
    let!(:split) { create(:split, slug: 'test-split') }

    it 'returns the slug of the associated split' do
      live_time = LiveTime.new(split: split)
      expect(live_time.split_slug).to eq(split.slug)
    end
  end

  describe '#split_slug=' do
    let!(:split) { create(:split, slug: 'test-split') }
    let(:live_time) { LiveTime.new }

    it 'finds the split having a slug equal to the provided param and sets split_id' do
      live_time.split_slug = 'test-split'
      expect(live_time.split).to eq(split)
    end

    it 'sets the split to nil if the slug is not found' do
      live_time.split_slug = 'nonexistent-split'
      expect(live_time.split_id).to be_nil
    end
  end
end
