# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PersonalInfo, type: :module do
  include ::ActiveSupport::Testing::TimeHelpers

  describe "birthday methods" do
    subject { build_stubbed(:effort, birthdate: birthdate) }

    before { allow(subject).to receive(:home_time_zone).and_return("Arizona") }
    before { travel_to "2020-12-15 12:00:00" }
    after { travel_back }

    describe "#birthday_notice" do
      context "when birthday is the same day" do
        let(:birthdate) { "1980-12-15" }
        it "returns Birthday today" do
          expect(subject.birthday_notice).to eq("Birthday today")
        end
      end

      context "when birthday is the next day" do
        let(:birthdate) { "1980-12-16" }
        it "returns Birthday tomorrow" do
          expect(subject.birthday_notice).to eq("Birthday tomorrow")
        end
      end

      context "when birthday is the previous day" do
        let(:birthdate) { "1980-12-14" }
        it "returns Birthday yesterday" do
          expect(subject.birthday_notice).to eq("Birthday yesterday")
        end
      end

      context "when birthday is in a future month" do
        let(:birthdate) { "1980-02-15" }
        it "returns the expected message" do
          expect(subject.birthday_notice).to eq("Birthday 62 days from now")
        end
      end

      context "when birthday is in a past month" do
        let(:birthdate) { "1980-10-15" }
        it "returns the expected message" do
          expect(subject.birthday_notice).to eq("Birthday 61 days ago")
        end
      end

      context "when birthdate does not exist" do
        let(:birthdate) { nil }
        it "returns nil" do
          expect(subject.birthday_notice).to be_nil
        end
      end
    end

    describe "#days_away_from_birthday" do
      context "when birthdate is the same day" do
        let(:birthdate) { "1980-12-15" }
        it "returns 0" do
          expect(subject.days_away_from_birthday).to eq(0)
        end
      end

      context "when birthdate is the next day" do
        let(:birthdate) { "1980-12-16" }
        it "returns 1" do
          expect(subject.days_away_from_birthday).to eq(1)
        end
      end

      context "when birthdate is the previous day" do
        let(:birthdate) { "1980-12-14" }
        it "returns -1" do
          expect(subject.days_away_from_birthday).to eq(-1)
        end
      end

      context "when birthdate is in a future month" do
        let(:birthdate) { "1980-02-15" }
        it "returns the expected value" do
          expect(subject.days_away_from_birthday).to eq(62)
        end
      end

      context "when birthdate is in a past month" do
        let(:birthdate) { "1980-10-15" }
        it "returns the expected value" do
          expect(subject.days_away_from_birthday).to eq(-61)
        end
      end

      context "when birthdate does not exist" do
        let(:birthdate) { nil }
        it "returns nil" do
          expect(subject.days_away_from_birthday).to be_nil
        end
      end
    end
  end

  describe '#current_age_from_birthdate' do
    subject { build_stubbed(:effort, birthdate: birthdate) }

    context 'when birthdate is not present' do
      let(:birthdate) { nil }

      it 'returns nil' do
        expect(subject.current_age_from_birthdate).to be_nil
      end
    end

    context 'when birthdate is present' do
      let(:birthdate) { Date.today - 20.years - 6.months }

      it 'calculates and returns the age' do
        expect(subject.current_age_from_birthdate).to eq(20)
      end
    end
  end

  describe '#state_and_country' do
    it 'returns the state and country of the subject resource' do
      effort = build_stubbed(:effort, country_code: 'CA', state_code: 'BC')
      expect(effort.state_and_country).to eq('British Columbia, Canada')
    end

    it 'abbreviates "United States" to "US"' do
      effort = build_stubbed(:effort, country_code: 'US', state_code: 'CO')
      expect(effort.state_and_country).to eq('Colorado, US')
    end

    it 'works even if the state is not recognized in Carmen' do
      effort = build_stubbed(:effort, country_code: 'GB', state_code: 'London')
      expect(effort.state_and_country).to eq('London, United Kingdom')
    end

    it 'returns the state_code if the country is not present' do
      effort = build_stubbed(:effort, country_code: nil, state_code: 'Atlantis')
      expect(effort.state_and_country).to eq('Atlantis')
    end

    it 'works properly when the country has no subregions' do
      effort = build_stubbed(:effort, country_code: 'HK', state_code: 'Hong Kong')
      expect(effort.state_and_country).to eq('Hong Kong, Hong Kong')
    end
  end

  describe '#flexible_geolocation' do
    context 'when the object includes a city, state, and country code of "US" or "CA"' do
      let(:effort_1) { build_stubbed(:effort, city: 'Louisville', state_code: 'CO', country_code: 'US') }
      let(:effort_2) { build_stubbed(:effort, city: 'Calgary', state_code: 'AB', country_code: 'CA') }

      it 'returns the city with the state code' do
        expect(effort_1.flexible_geolocation).to eq('Louisville, CO')
        expect(effort_2.flexible_geolocation).to eq('Calgary, AB')
      end
    end

    context 'when the object includes a city, state, and country code outside of the US or Canada' do
      let(:effort) { build_stubbed(:effort, city: 'Manzanillo', state_code: 'Colima', country_code: 'MX') }

      it 'returns the city, state code, and country' do
        expect(effort.flexible_geolocation).to eq('Manzanillo, Colima, Mexico')
      end
    end

    context 'when the object includes a state and country code of "US" or "CA" but no city' do
      let(:effort_1) { build_stubbed(:effort, city: nil, state_code: 'CO', country_code: 'US') }
      let(:effort_2) { build_stubbed(:effort, city: nil, state_code: 'AB', country_code: 'CA') }

      it 'returns the full state name without country code' do
        expect(effort_1.flexible_geolocation).to eq('Colorado')
        expect(effort_2.flexible_geolocation).to eq('Alberta')
      end
    end

    context 'when the object includes a state and country code other than "US" or "CA" but no city' do
      let(:effort) { build_stubbed(:effort, city: nil, state_code: 'Colima', country_code: 'MX') }

      it 'returns the state code and full country name' do
        expect(effort.flexible_geolocation).to eq('Colima, Mexico')
      end
    end

    context 'when the object includes a city and a country code but no state' do
      let(:effort_1) { build_stubbed(:effort, city: 'New York', state_code: nil, country_code: 'US') }
      let(:effort_2) { build_stubbed(:effort, city: 'Manzanillo', state_code: nil, country_code: 'MX') }

      it 'returns the city and full country name' do
        expect(effort_1.flexible_geolocation).to eq('New York, United States')
        expect(effort_2.flexible_geolocation).to eq('Manzanillo, Mexico')
      end
    end

    context 'when the object includes a country code but no city or state' do
      let(:effort_1) { build_stubbed(:effort, city: nil, state_code: nil, country_code: 'US') }
      let(:effort_2) { build_stubbed(:effort, city: nil, state_code: nil, country_code: 'MX') }

      it 'returns the full country name' do
        expect(effort_1.flexible_geolocation).to eq('United States')
        expect(effort_2.flexible_geolocation).to eq('Mexico')
      end
    end

    context 'when the object includes a city and state, but no country' do
      let(:effort_1) { build_stubbed(:effort, city: 'Louisville', state_code: 'CO', country_code: nil) }
      let(:effort_2) { build_stubbed(:effort, city: 'Calgary', state_code: 'AB', country_code: nil) }

      it 'returns the city with the state code' do
        expect(effort_1.flexible_geolocation).to eq('Louisville, CO')
        expect(effort_2.flexible_geolocation).to eq('Calgary, AB')
      end
    end
  end
end
