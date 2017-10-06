require 'rails_helper'

RSpec.describe Interactors::AssignGeoAttributes do
  describe '.perform' do
    let(:result) { Interactors::AssignGeoAttributes.perform(source, destination) }
    let(:source) { build_stubbed(:person, source_attributes) }
    let(:destination) { build_stubbed(:person, destination_attributes) }
    let(:modified_destination) { result.resources[:destination] }

    context 'when all destination attributes are nil' do
      let(:source_attributes) { {country_code: 'US', state_code: 'CO', city: 'Grand Junction'} }
      let(:destination_attributes) { {country_code: nil, state_code: nil, city: nil} }

      it 'assigns source country_code, state_code, and city to destination' do
        expect(modified_destination.country_code).to eq('US')
        expect(modified_destination.state_code).to eq('CO')
        expect(modified_destination.city).to eq('Grand Junction')
      end
    end

    context 'when states match and destination country is nil' do
      let(:source_attributes) { {country_code: 'US', state_code: 'CA'} }
      let(:destination_attributes) { {country_code: nil, state_code: 'CA'} }

      it 'assigns country data from source' do
        expect(modified_destination.country_code).to eq('US')
      end
    end

    context 'when destination state does not exist in country of source' do
      let(:source_attributes) { {country_code: 'MX', state_code: nil} }
      let(:destination_attributes) { {country_code: nil, state_code: 'CA'} }

      it 'does not assign country data from source' do
        expect(modified_destination.country_code).to be_nil
      end
    end

    context 'when source state does not exist in country of destination' do
      let(:source_attributes) { {country_code: 'CA', state_code: 'BC'} }
      let(:destination_attributes) { {country_code: 'US', state_code: nil} }

      it 'does not assign source state data to destination' do
        expect(modified_destination.state_code).to be_nil
      end
    end

    context 'when a country conflict exists' do
      let(:source_attributes) { {country_code: 'US', state_code: 'CO', city: 'Denver'} }
      let(:destination_attributes) { {country_code: 'MX', state_code: nil, city: nil} }

      it 'does not assign source country, state, or city data to destination' do
        expect(modified_destination.country_code).to eq('MX')
        expect(modified_destination.state_code).to be_nil
        expect(modified_destination.city).to be_nil
      end
    end

    context 'when a state conflict exists' do
      let(:source_attributes) { {country_code: 'US', state_code: 'CO', city: 'Denver'} }
      let(:destination_attributes) { {country_code: 'US', state_code: 'CA', city: nil} }

      it 'does not assign source state or city data to destination' do
        expect(modified_destination.country_code).to eq('US')
        expect(modified_destination.state_code).to eq('CA')
        expect(modified_destination.city).to be_nil
      end
    end

    context 'when a city conflict exists' do
      let(:source_attributes) { {country_code: 'US', state_code: 'CO', city: 'Denver'} }
      let(:destination_attributes) { {country_code: 'US', state_code: 'CO', city: 'Grand Junction'} }

      it 'does not assign source city data to destination' do
        expect(modified_destination.country_code).to eq('US')
        expect(modified_destination.state_code).to eq('CO')
        expect(modified_destination.city).to eq('Grand Junction')
      end
    end

    context 'when country is the same and source state is nil' do
      let(:source_attributes) { {country_code: 'US', state_code: nil, city: 'Denver'} }
      let(:destination_attributes) { {country_code: 'US', state_code: 'CO', city: nil} }

      it 'assigns source city to destination' do
        expect(modified_destination.country_code).to eq('US')
        expect(modified_destination.state_code).to eq('CO')
        expect(modified_destination.city).to eq('Denver')
      end
    end

    context 'when state is the same and source country is nil' do
      let(:source_attributes) { {country_code: nil, state_code: 'CA', city: 'Los Angeles'} }
      let(:destination_attributes) { {country_code: 'US', state_code: 'CA', city: nil} }

      it 'assigns source city to destination' do
        expect(modified_destination.country_code).to eq('US')
        expect(modified_destination.state_code).to eq('CA')
        expect(modified_destination.city).to eq('Los Angeles')
      end
    end

    context 'when state and country are the same and city is nil' do
      let(:source_attributes) { {country_code: 'US', state_code: 'CO', city: 'Grand Junction'} }
      let(:destination_attributes) { {country_code: 'US', state_code: 'CO', city: nil} }

      it 'assigns source city to destination' do
        expect(modified_destination.country_code).to eq('US')
        expect(modified_destination.state_code).to eq('CO')
        expect(modified_destination.city).to eq('Grand Junction')
      end
    end
  end
end
