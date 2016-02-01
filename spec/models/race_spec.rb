require "rails_helper"

RSpec.describe Race, type: :model do
  it "should be valid with a name" do
    race = Race.create!(name: 'Slow Mo 100')

    expect(Race.all.count).to(equal(1))
    expect(race).to be_valid
  end

  it "should be invalid without a name" do
    race = Race.new(name: nil)
    race.valid?
    expect(race.errors[:name].size).to eq(1)
  end

  it "should not allow duplicate names" do
    Race.create!(name: 'Hard Time 100')
    race = Race.new(name: 'Hard Time 100')
    race.valid?
    expect(race.errors[:name].size).to eq(1)
  end

end