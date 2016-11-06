require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe EventReconcileService do

  describe 'self.create_participants_from_efforts' do
    let(:course) { Course.create!(name: 'Test Course 100') }
    let(:event) { Event.create!(course: course, name: 'Test Event', start_time: '2012-08-08 05:00:00') }

    it 'should create nothing and return 0 when passed an empty array' do
      participant_count = Participant.count
      count = EventReconcileService.create_participants_from_efforts([])
      expect(Participant.count).to eq(participant_count)
      expect(count).to eq(0)
    end

    it 'should create a new participant for each valid effort' do
      effort1 = Effort.create!(event: event, first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      effort2 = Effort.create!(event: event, first_name: 'John', last_name: 'Hardster', gender: 'male')
      effort3 = Effort.create!(event: event, first_name: 'Jim', last_name: 'Hamster', gender: 'male')
      effort_ids = [effort1, effort2, effort3].map(&:id)
      participant_count = Participant.count
      EventReconcileService.create_participants_from_efforts(effort_ids)
      expect(Participant.count).to eq(participant_count + 3)
    end

    it 'should return a count of the new participants created' do
      effort1 = Effort.create!(event: event, first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      effort2 = Effort.create!(event: event, first_name: 'John', last_name: 'Hardster', gender: 'male')
      effort3 = Effort.create!(event: event, first_name: 'Jim', last_name: 'Hamster', gender: 'male')
      effort_ids = [effort1, effort2, effort3].map(&:id)
      count = EventReconcileService.create_participants_from_efforts(effort_ids)
      expect(count).to eq(3)
    end

  end

  describe 'self.assign_participants_to_efforts' do
    let(:course) { Course.create!(name: 'Test Course 100') }
    let(:event) { Event.create!(course: course, name: 'Test Event', start_time: '2012-08-08 05:00:00') }

    it 'should create nothing and return 0 when passed an empty hash' do
      participant_count = Participant.count
      effort_count = Effort.count
      count = EventReconcileService.assign_participants_to_efforts({})
      expect(Participant.count).to eq(participant_count)
      expect(Effort.count).to eq(effort_count)
      expect(count).to eq(0)
    end

    it 'should create no new participants and no new efforts' do
      effort1 = Effort.create!(event: event, first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      effort2 = Effort.create!(event: event, first_name: 'John', last_name: 'Hardster', gender: 'male')
      effort3 = Effort.create!(event: event, first_name: 'Jim', last_name: 'Hamster', gender: 'male')
      participant1 = Participant.create!(first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      participant2 = Participant.create!(first_name: 'John', last_name: 'Hardster', gender: 'male')
      participant3 = Participant.create!(first_name: 'Jim', last_name: 'Hamster', gender: 'male')
      id_hash = {effort1.id => participant1.id,
                 effort2.id => participant2.id,
                 effort3.id => participant3.id}
      participant_count = Participant.count
      effort_count = Effort.count
      EventReconcileService.assign_participants_to_efforts(id_hash)
      expect(Participant.count).to eq(participant_count)
      expect(Effort.count).to eq(effort_count)
    end

    it 'should assign each effort to the corresponding participant' do
      effort1 = Effort.create!(event: event, first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      effort2 = Effort.create!(event: event, first_name: 'John', last_name: 'Hardster', gender: 'male')
      effort3 = Effort.create!(event: event, first_name: 'Jim', last_name: 'Hamster', gender: 'male')
      participant1 = Participant.create!(first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      participant2 = Participant.create!(first_name: 'John', last_name: 'Hardster', gender: 'male')
      participant3 = Participant.create!(first_name: 'Jim', last_name: 'Hamster', gender: 'male')
      id_hash = {effort1.id => participant1.id,
                 effort2.id => participant2.id,
                 effort3.id => participant3.id}
      EventReconcileService.assign_participants_to_efforts(id_hash)
      expect(Effort.find(effort1.id).participant).to eq(participant1)
      expect(Effort.find(effort2.id).participant).to eq(participant2)
      expect(Effort.find(effort3.id).participant).to eq(participant3)
    end

    it 'should return a count of the participants assigned' do
      effort1 = Effort.create!(event: event, first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      effort2 = Effort.create!(event: event, first_name: 'John', last_name: 'Hardster', gender: 'male')
      effort3 = Effort.create!(event: event, first_name: 'Jim', last_name: 'Hamster', gender: 'male')
      participant1 = Participant.create!(first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      participant2 = Participant.create!(first_name: 'John', last_name: 'Hardster', gender: 'male')
      participant3 = Participant.create!(first_name: 'Jim', last_name: 'Hamster', gender: 'male')
      id_hash = {effort1.id => participant1.id,
                 effort2.id => participant2.id,
                 effort3.id => participant3.id}
      count = EventReconcileService.assign_participants_to_efforts(id_hash)
      expect(count).to eq(3)
    end

  end
end
