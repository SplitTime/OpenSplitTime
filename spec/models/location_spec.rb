require "rails_helper"

# t.string   "name"
# t.integer  "elevation"
# t.decimal  "latitude"
# t.decimal  "longitude"

RSpec.describe Location, type: :model do
  it "should be valid with only a name" do
    location = Location.create!(name: 'Putnam Basin')

    expect(Location.all.count).to eq(1)
    expect(location).to be_valid
  end

  it "should be invalid without a name" do
    location = Location.new(name: nil)
    expect(location).not_to be_valid
    expect(location.errors[:name]).to include("can't be blank")
  end

  it "should not allow duplicate names" do
    Location.create!(name: 'Hopeless')
    location = Location.new(name: 'Hopeless')
    expect(location).not_to be_valid
    expect(location.errors[:name]).to include("has already been taken")
  end

  it "should allow for a new location with valid elevation, latitude, and longitude" do
    location = Location.new(name: 'Mountain Hideout', elevation: 2600, latitude: 38.5, longitude: -104.5)
    expect(location).to be_valid
  end

  it "should not allow elevations less than -413 meters" do
    location = Location.new(name: 'Low Spot', elevation: -500)
    expect(location).not_to be_valid
    expect(location.errors[:elevation]).to include("must be greater than or equal to -413")
  end

  it "should not allow elevations greater than 8848 meters" do
    location = Location.new(name: 'High Spot', elevation: 9000)
    expect(location).not_to be_valid
    expect(location.errors[:elevation]).to include("must be less than or equal to 8848")
  end

  it "should not allow latitude less than -90" do
    location = Location.new(name: 'Far South', latitude: -100)
    expect(location).not_to be_valid
    expect(location.errors[:latitude]).to include("must be greater than or equal to -90")
  end

  it "should not allow latitude greater than 90" do
    location = Location.new(name: 'Far North', latitude: 100)
    expect(location).not_to be_valid
    expect(location.errors[:latitude]).to include("must be less than or equal to 90")
  end

  it "should not allow longitude less than -180" do
    location = Location.new(name: 'Far West', longitude: -200)
    expect(location).not_to be_valid
    expect(location.errors[:longitude]).to include("must be greater than or equal to -180")
  end

  it "should not allow longitude greater than 180" do
    location = Location.new(name: 'Far East', longitude: 200)
    expect(location).not_to be_valid
    expect(location.errors[:longitude]).to include("must be less than or equal to 180")
  end

end