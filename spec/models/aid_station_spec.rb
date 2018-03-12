require 'rails_helper'

# t.integer  "event_id"
# t.integer  "split_id"
# t.datetime "created_at",        null: false
# t.datetime "updated_at",        null: false
# t.datetime "open_time"
# t.datetime "close_time"
# t.integer  "status"
# t.string   "captain_name"
# t.string   "comms_crew_names"
# t.string   "comms_frequencies"
# t.string   "current_issues"

RSpec.describe AidStation, type: :model do
  subject { build_stubbed(:aid_station, split: split, event: event) }

  let(:course) { build_stubbed(:course) }
  let(:event) { build_stubbed(:event, course: course, name: 'Test Event', start_time: '2012-08-08 05:00:00') }
  let(:split) { build_stubbed(:split, course: course, base_name: 'Hopeless Outbound', distance_from_start: 50000) }
  let(:wrong_course) { build_stubbed(:course, name: 'Wrong Course') }
  let(:wrong_event) { build_stubbed(:event, course: wrong_course, name: 'Wrong Event', start_time: '2012-08-08 05:00:00') }
  let(:wrong_split) { build_stubbed(:split, course: wrong_course, base_name: 'Wrong Outbound', distance_from_start: 50000) }

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
      expect(aid_station.errors[:event_id]).to include("event's course is not the same as split's course")
    end

    context 'when an aid_station with the same event and split already exists' do
      let(:existing_course) { create(:course) }
      let(:existing_event) { create(:event, course: existing_course) }
      let(:existing_split) { create(:split, course: existing_course) }

      it 'does not allow for duplicate records with the same course and split' do
        create(:aid_station, event: existing_event, split: existing_split)
        aid_station = build_stubbed(:aid_station, event: existing_event, split: existing_split)
        expect(aid_station).not_to be_valid
        expect(aid_station.errors.full_messages.first).to include('only one of any given split permitted within an event')
      end
    end

    context 'for event_group split location validations' do
      let(:event_1) { create(:event, course: course_1, event_group: event_group) }
      let(:event_2) { create(:event, course: course_2, event_group: event_group) }
      let(:event_group) { create(:event_group) }
      let(:course_1) { create(:course) }
      let(:course_1_split_1) { create(:start_split, course: course_1, base_name: 'Start', latitude: 40, longitude: -105) }
      let(:course_1_split_2) { create(:finish_split, course: course_1, base_name: 'Finish', latitude: 42, longitude: -107) }
      let(:course_2) { create(:course) }
      let(:course_2_split_1) { create(:start_split, course: course_2, base_name: 'Start', latitude: 40, longitude: -105) }
      before do
        event_1.splits << course_1_split_1
        event_1.splits << course_1_split_2
        event_2.splits << course_2_split_1
      end

      context 'when an aid_station is added and all splits remain compatible within the event_group' do
        let(:course_2_split_2) { create(:finish_split, course: course_2, base_name: 'Finish', latitude: 42, longitude: -107) }

        it 'is invalid' do
          aid_station = create(:aid_station, event: event_2, split: course_2_split_2)
          expect(aid_station).to be_valid
        end
      end

      context 'when an aid_station is added resulting in an incompatible split within the event_group' do
        let(:course_2_split_2) { create(:finish_split, course: course_2, base_name: 'Finish', latitude: 41, longitude: -106) }

        it 'is invalid' do
          aid_station = create(:aid_station, event: event_2, split: course_2_split_2)
          expect(aid_station).not_to be_valid
          expect(aid_station.errors.full_messages).to include(/Split Finish is incompatible with similarly named splits within event group/)
        end
      end
    end
  end

  describe '#course' do
    it 'returns the course of the split' do
      expect(subject.course).to eq(course)
    end
  end

  describe '#course_name' do
    it 'returns the name of the course of the split' do
      expect(subject.course_name).to eq(course.name)
    end
  end

  describe '#event_group' do
    it 'returns the event_group of the event' do
      expect(subject.event_group).to eq(event.event_group)
    end
  end

  describe '#event_name' do
    it 'returns the name of the event' do
      expect(subject.event_name).to eq(event.name)
    end
  end

  describe '#organization' do
    it 'returns the organization of the event_group of the event' do
      expect(subject.organization).to eq(event.event_group.organization)
    end
  end

  describe '#organization_name' do
    it 'returns the name of the organization of the event_group of the event' do
      expect(subject.organization_name).to eq(event.event_group.organization.name)
    end
  end

  describe '#split_name' do
    it 'returns the base_name of the split' do
      expect(subject.split_name).to eq(split.base_name)
    end
  end
end
