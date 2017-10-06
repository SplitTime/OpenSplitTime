require 'rails_helper'

RSpec.describe Interactors::AssignPersonToEffort do
  describe '.perform' do
    let(:response) { Interactors::AssignPersonToEffort.perform(person, effort) }
    let(:person) { build_stubbed(:person, person_attributes) }
    let(:effort) { build_stubbed(:effort, effort_attributes) }
    let(:modified_effort) { response.resources[:effort] }
    let(:modified_person) { response.resources[:person] }

    let(:effort_attributes) { {} }
    let(:person_attributes) { {} }

    it 'assigns the person.id to effort.person_id' do
      expect(modified_effort.person_id).to eq(modified_person.id)
    end

    it 'sends a message to AssignGeoAttributes' do
      expect(Interactors::AssignGeoAttributes).to receive(:perform)
      response
    end

    context 'when person has no birthdate, email, or phone' do
      let(:effort_attributes) { {birthdate: '1999-01-01', email: 'user@example.com', phone: '3035551212'} }
      let(:person_attributes) { {birthdate: nil, email: nil, phone: nil} }

      it 'assigns the effort birthdate, email, and phone to person' do
        expect(modified_person.birthdate).to eq(modified_effort.birthdate)
        expect(modified_person.email).to eq(modified_effort.email)
        expect(modified_person.phone).to eq(modified_effort.phone)
      end
    end

    context 'when person has an existing birthdate, email, and phone and effort has none' do
      let(:effort_attributes) { {birthdate: nil, email: nil, phone: nil} }
      let(:person_attributes) { {birthdate: '1999-01-01', email: 'user@example.com', phone: '3035551212'} }

      it 'does not assign the effort birthdate, email, or phone to person' do
        expect(modified_person.birthdate).not_to eq(modified_effort.birthdate)
        expect(modified_person.email).not_to eq(modified_effort.email)
        expect(modified_person.phone).not_to eq(modified_effort.phone)
      end
    end

    context 'when person and effort have conflicting attributes' do
      let(:effort_attributes) { {email: 'user@example.com'} }
      let(:person_attributes) { {email: 'user@otherexample.com'} }

      it 'does not assign the conflicting attributes to person' do
        expect(modified_person.email).not_to eq(modified_effort.email)
      end
    end
  end
end
