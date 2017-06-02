require 'rails_helper'

RSpec.describe PersonalInfo, type: :module do

  describe '#state_and_country' do
    it 'returns the state and country of the subject resource' do
      effort = FactoryGirl.build_stubbed(:effort, country_code: 'CA', state_code: 'BC')
      expect(effort.state_and_country).to eq('British Columbia, Canada')
    end

    it 'abbreviates "United States" to "US"' do
      effort = FactoryGirl.build_stubbed(:effort, country_code: 'US', state_code: 'CO')
      expect(effort.state_and_country).to eq('Colorado, US')
    end

    it 'works even if the state is not recognized in Carmen' do
      effort = FactoryGirl.build_stubbed(:effort, country_code: 'GB', state_code: 'London')
      expect(effort.state_and_country).to eq('London, United Kingdom')
    end

    it 'returns the state_code if the country is not present' do
      effort = FactoryGirl.build_stubbed(:effort, country_code: nil, state_code: 'Atlantis')
      expect(effort.state_and_country).to eq('Atlantis')
    end

    it 'works properly when the country has no subregions' do
      effort = FactoryGirl.build_stubbed(:effort, country_code: 'HK', state_code: 'Hong Kong')
      expect(effort.state_and_country).to eq('Hong Kong, Hong Kong')
    end
  end
end
