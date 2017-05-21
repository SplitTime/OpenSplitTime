require 'rails_helper'

# t.integer  "event_id"
# t.integer  "split_id"

RSpec.describe AidStation, type: :model do
  let(:course) { FactoryGirl.build_stubbed(:course) }
  let(:event) { FactoryGirl.build_stubbed(:event, course: course, name: 'Test Event', start_time: '2012-08-08 05:00:00') }
  let(:split) { FactoryGirl.build_stubbed(:split, course: course, base_name: 'Hopeless Outbound', distance_from_start: 50000) }
  let(:wrong_course) { FactoryGirl.build_stubbed(:course, name: 'Wrong Course') }
  let(:wrong_event) { FactoryGirl.build_stubbed(:event, course: wrong_course, name: 'Wrong Event', start_time: '2012-08-08 05:00:00') }
  let(:wrong_split) { FactoryGirl.build_stubbed(:split, course: wrong_course, base_name: 'Wrong Outbound', distance_from_start: 50000) }

  describe '#initialize' do
    it 'is valid with an event and a split' do
      aid_station = AidStation.new(event: event, split: split)
      expect(aid_station).to be_valid
    end

    it 'is invalid without an event' do
      aid_station = AidStation.new(split: split)
      expect(aid_station).not_to be_valid
      expect(aid_station.errors[:event_id]).to include("can't be blank")
    end

    it 'is invalid without a split' do
      aid_station = AidStation.new(event: event)
      expect(aid_station).not_to be_valid
      expect(aid_station.errors[:split_id]).to include("can't be blank")
    end

    it 'is invalid if event course and split course are inconsistent' do
      aid_station = AidStation.new(event: event, split: wrong_split)
      expect(aid_station).not_to be_valid
      expect(aid_station.errors[:split_id]).to include("event's course is not the same as split's course")
      expect(aid_station.errors[:event_id]).to include("event's course is not the same as split's course")
    end

    context 'when an aid_station with the same event and split already exists' do
      let(:existing_course) { create(:course) }
      let(:existing_event) { create(:event, course: existing_course) }
      let(:existing_split) { create(:split, course: existing_course) }

      it 'does not allow for duplicate records with the same course and split' do
        create(:aid_station, event: existing_event, split: existing_split)
        aid_station = build(:aid_station, event: existing_event, split: existing_split)
        expect(aid_station).not_to be_valid
      end
    end
  end
end
