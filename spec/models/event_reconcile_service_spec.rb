require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe EventReconcileService do
  let(:course) { Course.create!(name: 'Test Course 100') }
  let(:event) { Event.create!(course: course, name: 'Test Event', start_time: '2012-08-08 05:00:00') }
  let(:effort1) { Effort.create!(event: event, first_name: 'Jen', last_name: 'Huckster', gender: 'female') }
  let(:effort2) { Effort.create!(event: event, first_name: 'John', last_name: 'Hardster', gender: 'male') }
  let(:effort3) { Effort.create!(event: event, first_name: 'Jim', last_name: 'Hamster', gender: 'male') }

  describe 'self.create_participants_from_efforts' do
    it 'should create nothing and return 0 when passed an empty array' do
      participant_count = Participant.count
      count = EventReconcileService.create_participants_from_efforts([])
      expect(Participant.count).to eq(participant_count)
      expect(count).to eq(0)
    end

    it 'should create a new participant for each valid effort' do
      effort_ids = [effort1, effort2, effort3].map(&:id)
      participant_count = Participant.count
      EventReconcileService.create_participants_from_efforts(effort_ids)
      expect(Participant.count).to eq(participant_count + 3)
    end

    it 'should return a count of the new participants created' do
      effort_ids = [effort1, effort2, effort3].map(&:id)
      count = EventReconcileService.create_participants_from_efforts(effort_ids)
      expect(count).to eq(3)
    end
  end

  describe 'self.assign_participants_to_efforts' do
    context 'when passed an empty hash' do
      it 'should create nothing and return 0' do
        count = EventReconcileService.assign_participants_to_efforts({})
        expect(Participant.count).to eq(0)
        expect(Effort.count).to eq(0)
        expect(count).to eq(0)
      end
    end

    context 'when passed a hash of valid effort_ids and participant_ids' do
      let(:participant1) { Participant.create!(first_name: 'Jen', last_name: 'Huckster', gender: 'female') }
      let(:participant2) { Participant.create!(first_name: 'John', last_name: 'Hardster', gender: 'male') }
      let(:participant3) { Participant.create!(first_name: 'Jim', last_name: 'Hamster', gender: 'male') }
      let(:id_hash) { {effort1.id => participant1.id,
                       effort2.id => participant2.id,
                       effort3.id => participant3.id} }

      it 'should assign each effort to the corresponding participant' do
        EventReconcileService.assign_participants_to_efforts(id_hash)
        expect(Effort.find(effort1.id).participant).to eq(participant1)
        expect(Effort.find(effort2.id).participant).to eq(participant2)
        expect(Effort.find(effort3.id).participant).to eq(participant3)
      end

      it 'should return a count of the participants assigned' do
        count = EventReconcileService.assign_participants_to_efforts(id_hash)
        expect(count).to eq(3)
      end
    end
  end

  describe 'self.associate_participants' do
    context 'when passed an empty hash' do
      it 'should create nothing and return 0' do
        params = ActionController::Parameters.new({})
        count = EventReconcileService.associate_participants(params)
        expect(Participant.count).to eq(0)
        expect(Effort.count).to eq(0)
        expect(count).to eq(0)
      end
    end

    context 'when passed an ActionControllers::Parameters object with valid effort_ids and participant_ids' do
      let(:participant1) { Participant.create!(first_name: 'Jen', last_name: 'Huckster', gender: 'female') }
      let(:participant2) { Participant.create!(first_name: 'John', last_name: 'Hardster', gender: 'male') }
      let(:participant3) { Participant.create!(first_name: 'Jim', last_name: 'Hamster', gender: 'male') }
      let(:id_hash) { {effort1.id => participant1.id,
                       effort2.id => participant2.id,
                       effort3.id => participant3.id} }
      let(:params) { ActionController::Parameters.new(id_hash) }

      it 'should assign efforts to participants' do
        EventReconcileService.associate_participants(params)
        expect(Effort.find(effort1.id).participant).to eq(participant1)
        expect(Effort.find(effort2.id).participant).to eq(participant2)
        expect(Effort.find(effort3.id).participant).to eq(participant3)
      end

      it 'should return an integer representing the number of assigned pairs' do
        count = EventReconcileService.associate_participants(params)
        expect(count).to eq(3)
      end
    end
  end
end