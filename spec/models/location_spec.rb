require 'rails_helper'

# t.string   "name"
# t.integer  "elevation"
# t.decimal  "latitude"
# t.decimal  "longitude"

RSpec.describe Location, type: :model do
  it_behaves_like 'auditable'
  it_behaves_like 'unit_conversions'
  it { is_expected.to strip_attribute(:name).collapse_spaces }
  it { is_expected.to strip_attribute(:description).collapse_spaces }

  describe '#initialize' do
    it 'is valid with only a name' do
      location = Location.create!(name: 'Putnam Basin')
      expect(Location.all.count).to eq(1)
      expect(location).to be_valid
    end

    it 'is invalid without a name' do
      location = Location.new(name: nil)
      expect(location).not_to be_valid
      expect(location.errors[:name]).to include("can't be blank")
    end

    it 'does not allow duplicate names' do
      Location.create!(name: 'Hopeless')
      location = Location.new(name: 'Hopeless')
      expect(location).not_to be_valid
      expect(location.errors[:name]).to include('has already been taken')
    end

    it 'allows for a new location with valid elevation, latitude, and longitude' do
      location = Location.new(name: 'Mountain Hideout', elevation: 2600, latitude: 38.5, longitude: -104.5)
      expect(location).to be_valid
    end

    it 'does not allow elevations less than -413 meters' do
      location = Location.new(name: 'Low Spot', elevation: -500)
      expect(location).not_to be_valid
      expect(location.errors[:elevation]).to include('must be greater than or equal to -413')
    end

    it 'does not allow elevations greater than 8848 meters' do
      location = Location.new(name: 'High Spot', elevation: 9000)
      expect(location).not_to be_valid
      expect(location.errors[:elevation]).to include('must be less than or equal to 8848')
    end

    it 'does not allow latitude less than -90' do
      location = Location.new(name: 'Far South', latitude: -100)
      expect(location).not_to be_valid
      expect(location.errors[:latitude]).to include('must be greater than or equal to -90')
    end

    it 'does not allow latitude greater than 90' do
      location = Location.new(name: 'Far North', latitude: 100)
      expect(location).not_to be_valid
      expect(location.errors[:latitude]).to include('must be less than or equal to 90')
    end

    it 'does not allow longitude less than -180' do
      location = Location.new(name: 'Far West', longitude: -200)
      expect(location).not_to be_valid
      expect(location.errors[:longitude]).to include('must be greater than or equal to -180')
    end

    it 'does not allow longitude greater than 180' do
      location = Location.new(name: 'Far East', longitude: 200)
      expect(location).not_to be_valid
      expect(location.errors[:longitude]).to include('must be less than or equal to 180')
    end
  end

  describe '#elevation_as_entered' do
    it 'returns nil if elevation is not present' do
      location = Location.new(latitude: 38.5, longitude: -104.5)
      expect(location.elevation_as_entered).to be_nil
    end

    it 'returns elevation in feet if preferred elevation units is set to "feet"' do
      location = Location.new(latitude: 38.5, longitude: -104.5, elevation: 1000)
      allow(Location).to receive(:pref_elevation_unit).and_return('feet')
      expect(location.elevation_as_entered).to be_within(1).of(3280)
    end

    it 'returns elevation in meters if preferred elevation units is set to "meters"' do
      location = Location.new(latitude: 38.5, longitude: -104.5, elevation: 1000)
      allow(Location).to receive(:pref_elevation_unit).and_return('meters')
      expect(location.elevation_as_entered).to be_within(1).of(1000)
    end
  end

  describe '#elevation_as_entered=' do
    it 'sets elevation to nil if parameter is not present' do
      location = Location.new(latitude: 38.5, longitude: -104.5, elevation: 1000)
      location.elevation_as_entered = nil
      expect(location.elevation).to be_nil
    end

    it 'understands the parameter as feet if preferred elevation units is set to "feet"' do
      location = Location.new(latitude: 38.5, longitude: -104.5, elevation: nil)
      allow(Location).to receive(:pref_elevation_unit).and_return('feet')
      location.elevation_as_entered = 3280
      expect(location.elevation).to be_within(1).of(1000)
    end

    it 'understands the parameter as meters if preferred elevation units is set to "meters"' do
      location = Location.new(latitude: 38.5, longitude: -104.5, elevation: nil)
      allow(Location).to receive(:pref_elevation_unit).and_return('meters')
      location.elevation_as_entered = 1000
      expect(location.elevation).to be_within(1).of(1000)
    end

    it 'ignores non-numeric characters' do
      location = Location.new(latitude: 38.5, longitude: -104.5, elevation: nil)
      allow(Location).to receive(:pref_elevation_unit).and_return('feet')
      location.elevation_as_entered = '3,280 feet'
      expect(location.elevation).to be_within(1).of(1000)
    end
  end
end