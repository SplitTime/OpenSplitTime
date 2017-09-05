require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe EventReconcileService do
  let(:course) { create(:course) }
  let(:event) { create(:event, course: course) }
  let(:effort1) { Effort.create!(event: event, first_name: 'Jen', last_name: 'Huckster', gender: 'female') }
  let(:effort2) { Effort.create!(event: event, first_name: 'John', last_name: 'Hardster', gender: 'male') }
  let(:effort3) { Effort.create!(event: event, first_name: 'Jim', last_name: 'Hamster', gender: 'male') }

  describe '.create_people_from_efforts' do
    it 'creates nothing and returns 0 when passed an empty array' do
      person_count = Person.count
      count = EventReconcileService.create_people_from_efforts([])
      expect(Person.count).to eq(person_count)
      expect(count).to eq(0)
    end

    it 'creates a single new person if given a single effort_id' do
      effort_id = effort1.id
      person_count = Person.count
      EventReconcileService.create_people_from_efforts(effort_id)
      expect(Person.count).to eq(person_count + 1)
    end

    it 'creates a new person for each valid effort' do
      effort_ids = [effort1, effort2, effort3].map(&:id)
      person_count = Person.count
      EventReconcileService.create_people_from_efforts(effort_ids)
      expect(Person.count).to eq(person_count + 3)
    end

    it 'returns a count of the new people created' do
      effort_ids = [effort1, effort2, effort3].map(&:id)
      count = EventReconcileService.create_people_from_efforts(effort_ids)
      expect(count).to eq(3)
    end
  end

  describe '.assign_people_to_efforts' do
    context 'when passed an empty hash' do
      it 'creates nothing and returns 0' do
        count = EventReconcileService.assign_people_to_efforts({})
        expect(Person.count).to eq(0)
        expect(Effort.count).to eq(0)
        expect(count).to eq(0)
      end
    end

    context 'when passed a hash of valid effort_ids and person_ids as integers' do
      let(:person1) { Person.create!(first_name: 'Jen', last_name: 'Huckster', gender: 'female') }
      let(:person2) { Person.create!(first_name: 'John', last_name: 'Hardster', gender: 'male') }
      let(:person3) { Person.create!(first_name: 'Jim', last_name: 'Hamster', gender: 'male') }
      let(:id_hash) { {effort1.id => person1.id,
                       effort2.id => person2.id,
                       effort3.id => person3.id} }

      it 'assigns each effort to the corresponding person' do
        EventReconcileService.assign_people_to_efforts(id_hash)
        expect(Effort.find(effort1.id).person).to eq(person1)
        expect(Effort.find(effort2.id).person).to eq(person2)
        expect(Effort.find(effort3.id).person).to eq(person3)
      end

      it 'returns a count of the people assigned' do
        count = EventReconcileService.assign_people_to_efforts(id_hash)
        expect(count).to eq(3)
      end
    end
  end

  context 'when passed an hash of valid effort_ids and person_ids as strings' do
    let(:person1) { Person.create!(first_name: 'Jen', last_name: 'Huckster', gender: 'female') }
    let(:person2) { Person.create!(first_name: 'John', last_name: 'Hardster', gender: 'male') }
    let(:person3) { Person.create!(first_name: 'Jim', last_name: 'Hamster', gender: 'male') }
    let(:id_hash) { {effort1.id.to_s => person1.id.to_s,
                     effort2.id.to_s => person2.id.to_s,
                     effort3.id.to_s => person3.id.to_s} }
    let(:params) { ActionController::Parameters.new(ids: id_hash) }

    it 'assigns each effort to the corresponding person' do
      id_hash = params[:ids].to_unsafe_h
      EventReconcileService.assign_people_to_efforts(id_hash)
      expect(Effort.find(effort1.id).person).to eq(person1)
      expect(Effort.find(effort2.id).person).to eq(person2)
      expect(Effort.find(effort3.id).person).to eq(person3)
    end

    it 'returns a count of the people assigned' do
      count = EventReconcileService.assign_people_to_efforts(id_hash)
      expect(count).to eq(3)
    end
  end
end
