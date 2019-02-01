# frozen_string_literal: true

require 'rails_helper'

# t.integer "event_id"
# t.integer "split_id"
# t.datetime "created_at", null: false
# t.datetime "updated_at", null: false

RSpec.describe AidStation, type: :model do
  subject(:aid_station) { AidStation.new(event: event, split: split) }

  let(:event) { events(:sum_100k) }
  let(:split) { splits(:sum_100k_course_finish) }
  let(:course) { event.course }
  let(:event_group) { event.event_group }
  let(:organization) { event_group.organization }

  describe '#initialize' do
    context 'with an event and a split that are not already paired' do
      before { event.splits.delete(split) }

      it 'is valid' do
        expect(aid_station).to be_valid
      end
    end

    context 'without an event' do
      let(:event) { nil }

      it 'is invalid' do
        expect(aid_station).not_to be_valid
        expect(aid_station.errors[:event_id]).to include("can't be blank")
      end
    end

    context 'if event course and split course are inconsistent' do
      let(:split) { splits(:sum_55k_course_finish) }

      it 'is invalid' do
        expect(aid_station).not_to be_valid
        expect(aid_station.errors[:event_id]).to include("event's course is not the same as split's course")
      end
    end

    context 'when an aid_station with the same event and split already exists' do
      it 'does not allow for duplicate records with the same course and split' do
        expect(aid_station).not_to be_valid
        expect(aid_station.errors.full_messages.first).to include('only one of any given split permitted within an event')
      end
    end

    context 'for event_group split location validations' do
      let(:event_1) { create(:event, course: course_1, event_group: event_group, home_time_zone: 'Arizona') }
      let(:event_2) { create(:event, course: course_2, event_group: event_group, home_time_zone: 'Arizona') }
      let(:event_group) { create(:event_group) }
      let(:course_1) { create(:course) }
      let(:course_1_split_1) { create(:split, :start, course: course_1, base_name: 'Start', latitude: 40, longitude: -105) }
      let(:course_1_split_2) { create(:split, :finish, course: course_1, base_name: 'Finish', latitude: 42, longitude: -107) }
      let(:course_2) { create(:course) }
      let(:course_2_split_1) { create(:split, :start, course: course_2, base_name: 'Start', latitude: 40, longitude: -105) }
      before do
        event_1.splits << course_1_split_1
        event_1.splits << course_1_split_2
        event_2.splits << course_2_split_1
      end

      context 'when an aid_station is added and all splits remain compatible within the event_group' do
        let(:course_2_split_2) { create(:split, :finish, course: course_2, base_name: 'Finish', latitude: 42, longitude: -107) }

        it 'is valid' do
          aid_station = create(:aid_station, event: event_2, split: course_2_split_2)
          expect(aid_station).to be_valid
        end
      end

      context 'when an aid_station is added and a splits becomes incompatible within the event_group' do
        let(:course_2_split_2) { create(:split, :finish, course: course_2, base_name: 'Finish', latitude: 40, longitude: -105) }

        it 'is invalid' do
          expect { create(:aid_station, event: event_2, split: course_2_split_2) }.to raise_error ActiveRecord::RecordInvalid
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
      expect(subject.event_group).to eq(event_group)
    end
  end

  describe '#event_name' do
    it 'returns the name of the event' do
      expect(subject.event_name).to eq(event.name)
    end
  end

  describe '#organization' do
    it 'returns the organization of the event_group of the event' do
      expect(subject.organization).to eq(organization)
    end
  end

  describe '#organization_name' do
    it 'returns the name of the organization of the event_group of the event' do
      expect(subject.organization_name).to eq(organization.name)
    end
  end

  describe '#split_name' do
    it 'returns the base_name of the split' do
      expect(subject.split_name).to eq(split.base_name)
    end
  end
end
