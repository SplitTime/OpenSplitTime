require 'spec_helper'

shared_examples_for 'unit_conversions' do
  let (:model) { described_class }

  describe 'entered_distance_to_meters' do
    it 'converts a number in miles to meters' do
      expect(model.entered_distance_to_meters(10.0).round(0)).to eq(16093)
    end

    it 'converts a string numeric in miles to meters' do
      expect(model.entered_distance_to_meters('10.0').round(0)).to eq(16093)
    end

    it 'ignores non-numeric characters in the string' do
      expect(model.entered_distance_to_meters('10.0 leagues').round(0)).to eq(16093)
    end
  end

  describe 'entered_elevation_to_meters' do
    it 'converts a numeric in preferred units to meters' do
      expect(model.entered_elevation_to_meters(29029).round(0)).to eq(8848)
    end

    it 'converts a string numeric in preferred units to meters' do
      expect(model.entered_elevation_to_meters('29029').round(0)).to eq(8848)
    end

    it 'ignores non-numeric characters in the string' do
      expect(model.entered_elevation_to_meters('29,029 cubits').round(0)).to eq(8848)
    end
  end

  describe 'preferred_distance_in_meters' do
    it 'converts miles to meters by default' do
      expect(model.preferred_distance_in_meters(5.5)).to eq(8851)
    end
  end

  describe 'preferred_elevation_in_meters' do
    it 'converts meters to feet by default' do
      expect(model.preferred_elevation_in_meters(29029).round(0)).to eq(8848)
    end
  end

  describe 'distance_in_preferred_units' do
    it 'converts meters to miles by default' do
      expect(model.distance_in_preferred_units(8851).round(1)).to eq(5.5)
    end
  end

  describe 'elevation_in_preferred_units' do
    it 'converts meters to feet by default' do
      expect(model.elevation_in_preferred_units(8848).round(0)).to eq(29029)
    end
  end

  describe 'numericize' do
    it 'accepts a fixnum and returns it without modification' do
      expect(model.numericize(5050)).to eq(5050)
    end

    it 'converts a number string to a float' do
      expect(model.numericize('5050.50')).to eq(5050.5)
    end

    it 'removes commas and other non-numeric characters' do
      expect(model.numericize('14,000 feet')).to eq(14000)
    end
  end

end