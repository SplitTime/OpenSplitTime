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
  end

  describe '#full_name=' do
    context 'when provided with a two-word name' do
      let(:full_name) { 'Joe Hardman' }

      it 'assigns the first word of the provided string to first_name and the last word to last_name' do
        effort = Effort.new(full_name: full_name)
        expect(effort.first_name).to eq('Joe')
        expect(effort.last_name).to eq('Hardman')
      end
    end

    context 'when provided with a three-word name' do
      let(:full_name) { 'Billy Bob Thornton'}

      it 'assigns the first two words of the provided string to first_name and the last word to last_name' do
        effort = Effort.new(full_name: full_name)
        expect(effort.first_name).to eq('Billy Bob')
        expect(effort.last_name).to eq('Thornton')
      end
    end

    context 'when provided with a one-word name' do
      let(:full_name) { 'Johnny' }

      it 'assigns the name to first_name' do
        effort = Effort.new(full_name: full_name)
        expect(effort.first_name).to eq('Johnny')
        expect(effort.last_name).to be_nil
      end
    end

    context 'when provided with an empty string' do
      let(:full_name) { '' }

      it 'assigns nil to both first_name and last_name' do
        effort = Effort.new(full_name: full_name)
        expect(effort.first_name).to be_nil
        expect(effort.last_name).to be_nil
      end
    end

    context 'when provided with nil' do
      let(:full_name) { nil }

      it 'assigns nil to both first_name and last_name' do
        effort = Effort.new(full_name: full_name)
        expect(effort.first_name).to be_nil
        expect(effort.last_name).to be_nil
      end
    end
  end
end
