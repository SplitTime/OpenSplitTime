require 'rails_helper'

RSpec.describe PersonalInfo, type: :module do

  describe '#state_and_country' do

    it 'should return the state and country of the subject resource' do
      effort = FactoryGirl.build_stubbed(:effort, country_code: 'CA', state_code: 'BC')
      expect(effort.state_and_country).to eq('British Columbia, Canada')
    end

    it 'should abbreviate "United States" to "US"' do
      effort = FactoryGirl.build_stubbed(:effort, country_code: 'US', state_code: 'CO')
      expect(effort.state_and_country).to eq('Colorado, US')
    end

    it 'should work even if the state is not recognized in Carmen' do
      effort = FactoryGirl.build_stubbed(:effort, country_code: 'GB', state_code: 'London')
      expect(effort.state_and_country).to eq('London, United Kingdom')
    end

    it 'should return the state_code if the country is not present' do
      effort = FactoryGirl.build_stubbed(:effort, country_code: nil, state_code: 'Atlantis')
      expect(effort.state_and_country).to eq('Atlantis')
    end
  end
end