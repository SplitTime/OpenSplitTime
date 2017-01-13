require 'rails_helper'

# t.integer  "course_id"
# t.integer  "race_id"
# t.string   "name"
# t.datetime "start_time"

RSpec.describe Event, type: :model do
  it { is_expected.to strip_attribute(:name).collapse_spaces }

  describe 'initialize' do
    let(:course) { Course.create!(name: 'Slo Mo 100 CCW') }
    let(:course2) { Course.create!(name: 'Slo Mo 100 CW') }

    it 'is valid when created with a course, a name, and a start time' do
      event = Event.create!(course: course, name: 'Slo Mo 100 2015', start_time: '2015-07-01 06:00:00', laps_required: 1)

      expect(Event.all.count).to eq(1)
      expect(event.course).to eq(course)
      expect(event.name).to eq('Slo Mo 100 2015')
      expect(event.start_time).to eq('2015-07-01 06:00:00'.in_time_zone)
      expect(event).to be_valid
    end

    it 'is invalid without a course' do
      event = Event.new(course: nil, name: 'Slo Mo 100 2015', start_time: '2015-07-01', laps_required: 1)
      expect(event).not_to be_valid
      expect(event.errors[:course_id]).to include("can't be blank")
    end

    it 'is invalid without a name' do
      event = Event.new(course: course, name: nil, start_time: '2015-07-01', laps_required: 1)
      expect(event).not_to be_valid
      expect(event.errors[:name]).to include("can't be blank")
    end

    it 'is invalid without a start date' do
      event = Event.new(course: course, name: 'Slo Mo 100 2015', start_time: nil, laps_required: 1)
      expect(event).not_to be_valid
      expect(event.errors[:start_time]).to include("can't be blank")
    end

    it 'is invalid without a laps_required' do
      event = Event.new(course: course, name: 'Slo Mo 100 2015', start_time: '2015-07-01', laps_required: nil)
      expect(event).not_to be_valid
      expect(event.errors[:laps_required]).to include("can't be blank")
    end

    it 'does not permit duplicate names' do
      Event.create!(course: course, name: 'Slo Mo 100 2015', start_time: '2015-07-01', laps_required: 1)
      event = Event.new(course: course2, name: 'Slo Mo 100 2015', start_time: '2016-07-01', laps_required: 1)
      expect(event).not_to be_valid
      expect(event.errors[:name]).to include('has already been taken')
    end
  end

  describe '#lap_splits' do
    let(:event) { FactoryGirl.build_stubbed(:event, laps_required: 2) }
    let(:start_split) { FactoryGirl.build_stubbed(:start_split, id: 111) }
    let(:intermediate_split1) { FactoryGirl.build_stubbed(:split, id: 102) }
    let(:intermediate_split2) { FactoryGirl.build_stubbed(:split, id: 103) }
    let(:finish_split) { FactoryGirl.build_stubbed(:finish_split, id: 112) }
    let(:splits) { [start_split, intermediate_split1, intermediate_split2, finish_split] }

    it 'returns an array of TimePoint objects ordered by lap, split distance, and bitkey' do
      test_event = event
      ordered_splits = splits
      allow(test_event).to receive(:ordered_splits).and_return(ordered_splits)
      lap_splits = test_event.lap_splits
      expect(lap_splits.size).to eq(8)
      expect(lap_splits.map(&:lap)).to eq([1] * 4 + [2] * 4)
      expect(lap_splits.map(&:split).map(&:id)).to eq([111, 102, 103, 112] * 2)
    end
  end

  describe '#time_points' do
    let(:event) { FactoryGirl.build_stubbed(:event, laps_required: 2) }
    let(:start_split) { FactoryGirl.build_stubbed(:start_split, id: 111) }
    let(:intermediate_split1) { FactoryGirl.build_stubbed(:split, id: 102) }
    let(:intermediate_split2) { FactoryGirl.build_stubbed(:split, id: 103) }
    let(:finish_split) { FactoryGirl.build_stubbed(:finish_split, id: 112) }
    let(:splits) { [start_split, intermediate_split1, intermediate_split2, finish_split] }

    it 'returns an array of TimePoint objects ordered by lap, split distance, and bitkey' do
      test_event = event
      ordered_splits = splits
      allow(test_event).to receive(:ordered_splits).and_return(ordered_splits)
      time_points = test_event.time_points
      expect(time_points.size).to eq(12)
      expect(time_points.map(&:lap)).to eq([1] * 6 + [2] * 6)
      expect(time_points.map(&:split_id)).to eq([111, 102, 102, 103, 103, 112] * 2)
      expect(time_points.map(&:bitkey)).to eq([1, 1, 64, 1, 64, 1] * 2)
    end
  end

  describe '#laps' do
    it 'returns an array containing [1] when laps_required is 1' do
      event = FactoryGirl.build_stubbed(:event, laps_required: 1)
      expected = [1]
      expect(event.laps).to eq(expected)
    end

    it 'returns an array containing all lap numbers' do
      event = FactoryGirl.build_stubbed(:event, laps_required: 5)
      expected = [1, 2, 3, 4, 5]
      expect(event.laps).to eq(expected)
    end
  end
end