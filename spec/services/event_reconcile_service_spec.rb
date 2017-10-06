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
end
