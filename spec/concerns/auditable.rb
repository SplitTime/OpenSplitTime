require 'spec_helper'

shared_examples_for 'auditable' do
  let (:model) { described_class }

  describe 'before validation' do
    it 'adds the current user id to created_by and updated_by' do
      current_user_id = 1
      model_name = model.to_sym
      allow(User).to receive(:current).and_return(current_user_id)
      resource = FactoryGirl.build(model.to_sym, created_by: nil, updated_by: nil)

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

  describe 'meters_to_preferred_distance' do
    it 'converts meters to miles by default' do
      expect(model.meters_to_preferred_distance(8851).round(1)).to eq(5.5)
    end
  end

  describe 'meters_to_preferred_elevation' do
    it 'converts meters to feet by default' do
      expect(model.meters_to_preferred_elevation(8848).round(0)).to eq(29029)
    end
  end
end