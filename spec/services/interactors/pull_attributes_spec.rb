require 'rails_helper'

RSpec.describe Interactors::PullAttributes do
  describe '.perform' do
    let(:response) { Interactors::PullAttributes.perform(source, destination, attributes) }
    let(:source) { build_stubbed(:effort, source_attributes) }
    let(:destination) { build_stubbed(:person, destination_attributes) }
    let(:attributes) { [:birthdate, :email, :phone] }
    let(:modified_destination) { response.resources[:destination] }

    context 'when destination has no birthdate, email, or phone' do
      let(:source_attributes) { {birthdate: '1999-01-01', email: 'user@example.com', phone: '3035551212'} }
      let(:destination_attributes) { {birthdate: nil, email: nil, phone: nil} }

      it 'assigns the source birthdate, email, and phone to destination' do
        expect(modified_destination.birthdate).to eq(source.birthdate)
        expect(modified_destination.email).to eq(source.email)
        expect(modified_destination.phone).to eq(source.phone)
      end
    end

    context 'when destination has an existing birthdate, email, and phone and source has none' do
      let(:source_attributes) { {birthdate: nil, email: nil, phone: nil} }
      let(:destination_attributes) { {birthdate: '1999-01-01', email: 'user@example.com', phone: '3035551212'} }

      it 'does not assign the source birthdate, email, or phone to destination' do
        expect(modified_destination.birthdate).not_to eq(source.birthdate)
        expect(modified_destination.email).not_to eq(source.email)
        expect(modified_destination.phone).not_to eq(source.phone)
      end
    end

    context 'when destination and source have conflicting attributes' do
      let(:source_attributes) { {email: 'user@example.com'} }
      let(:destination_attributes) { {email: 'user@otherexample.com'} }

      it 'does not assign the conflicting attributes to destination' do
        expect(modified_destination.email).not_to eq(source.email)
      end
    end
  end
end
