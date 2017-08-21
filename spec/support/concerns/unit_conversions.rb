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
