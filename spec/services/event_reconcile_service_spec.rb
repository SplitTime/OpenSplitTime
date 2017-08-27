require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe EventReconcileService do
  let(:course) { create(:course) }
  let(:event) { create(:event, course: course) }
  let(:effort1) { Effort.create!(event: event, first_name: 'Jen', last_name: 'Huckster', gender: 'female') }
  let(:effort2) { Effort.create!(event: event, first_name: 'John', last_name: 'Hardster', gender: 'male') }
  let(:effort3) { Effort.create!(event: event, first_name: 'Jim', last_name: 'Hamster', gender: 'male') }

  describe '.create_participants_from_efforts' do
    it 'creates nothing and returns 0 when passed an empty array' do
      participant_count = Participant.count
      count = EventReconcileService.create_participants_from_efforts([])
      expect(Participant.count).to eq(participant_count)
      expect(count).to eq(0)
    end

    it 'creates a single new participant if given a single effort_id' do
      effort_id = effort1.id
      participant_count = Participant.count
      EventReconcileService.create_participants_from_efforts(effort_id)
      expect(Participant.count).to eq(participant_count + 1)
    end

    it 'creates a new participant for each valid effort' do
      effort_ids = [effort1, effort2, effort3].map(&:id)
      participant_count = Participant.count
      EventReconcileService.create_participants_from_efforts(effort_ids)
      expect(Participant.count).to eq(participant_count + 3)
    end

    it 'returns a count of the new participants created' do
      effort_ids = [effort1, effort2, effort3].map(&:id)
      count = EventReconcileService.create_participants_from_efforts(effort_ids)
      expect(count).to eq(3)
    end
  end

  describe '.assign_participants_to_efforts' do
    context 'when passed an empty hash' do
      it 'creates nothing and returns 0' do
        count = EventReconcileService.assign_participants_to_efforts({})
        expect(Participant.count).to eq(0)
        expect(Effort.count).to eq(0)
        expect(count).to eq(0)
      end
    end

    context 'when passed a hash of valid effort_ids and participant_ids as integers' do
      let(:participant1) { Participant.create!(first_name: 'Jen', last_name: 'Huckster', gender: 'female') }
      let(:participant2) { Participant.create!(first_name: 'John', last_name: 'Hardster', gender: 'male') }
      let(:participant3) { Participant.create!(first_name: 'Jim', last_name: 'Hamster', gender: 'male') }
      let(:id_hash) { {effort1.id => participant1.id,
                       effort2.id => participant2.id,
                       effort3.id => participant3.id} }

      it 'assigns each effort to the corresponding participant' do
        EventReconcileService.assign_participants_to_efforts(id_hash)
        expect(Effort.find(effort1.id).participant).to eq(participant1)
        expect(Effort.find(effort2.id).participant).to eq(participant2)
        expect(Effort.find(effort3.id).participant).to eq(participant3)
      end

      it 'returns a count of the participants assigned' do
        count = EventReconcileService.assign_participants_to_efforts(id_hash)
        expect(count).to eq(3)
      end
    end
  end

  context 'when passed an hash of valid effort_ids and participant_ids as strings' do
    let(:participant1) { Participant.create!(first_name: 'Jen', last_name: 'Huckster', gender: 'female') }
    let(:participant2) { Participant.create!(first_name: 'John', last_name: 'Hardster', gender: 'male') }
    let(:participant3) { Participant.create!(first_name: 'Jim', last_name: 'Hamster', gender: 'male') }
    let(:id_hash) { {effort1.id.to_s => participant1.id.to_s,
                     effort2.id.to_s => participant2.id.to_s,
                     effort3.id.to_s => participant3.id.to_s} }
    let(:params) { ActionController::Parameters.new(ids: id_hash) }

    it 'assigns each effort to the corresponding participant' do
      id_hash = params[:ids].to_unsafe_h
      EventReconcileService.assign_participants_to_efforts(id_hash)
      expect(Effort.find(effort1.id).participant).to eq(participant1)
      expect(Effort.find(effort2.id).participant).to eq(participant2)
      expect(Effort.find(effort3.id).participant).to eq(participant3)
    end

    it 'returns a count of the participants assigned' do
      count = EventReconcileService.assign_participants_to_efforts(id_hash)
      expect(count).to eq(3)
    end
  end
end
