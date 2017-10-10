require 'rails_helper'

RSpec.describe EventTimeRounder do
  describe '#initialize' do
    it 'initializes with an event in an args hash' do
      event = Event.new
      expect { EventTimeRounder.new(event: event) }
          .not_to raise_error
    end

    it 'raises an ArgumentError if no event or event_id is given' do
      expect { EventTimeRounder.new(random_param: 123) }
          .to raise_error(/must include one of event or event_id/)
    end
  end

  describe '#fix_excel_import' do
    before do
      FactoryGirl.reload
      course = create(:course)
      create_list(:splits_hardrock_ccw, 16, course: course)
      event = create(:event, course: course)
      effort = create(:effort, event: event)
      create_list(:split_times_hardrock_45, 5, effort: effort)
    end

    it 'rounds intermediate split_times ending in :59 and :01 to the nearest minute' do
      event = Event.first
      split_times = event.split_times
      split_times[1].update(time_from_start: split_times[1].time_from_start - 1)
      split_times[2].update(time_from_start: split_times[2].time_from_start + 1)
      expect(split_times.select { |st| split_time_damaged?(st) }.size).to eq(2)
      EventTimeRounder.fix_excel_import(event: event)
      split_times = event.split_times
      expect(split_times.select { |st| split_time_damaged?(st) }.size).to eq(0)
    end

    def split_time_damaged?(st)
      [1, 59].include?(st.time_from_start % 60)
    end
  end
end
