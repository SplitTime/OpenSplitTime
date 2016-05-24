require "rails_helper"

# t.string   "name"
# t.string   "description"

RSpec.describe Race, type: :model do
  it { is_expected.to strip_attribute(:name).collapse_spaces }
  it { is_expected.to strip_attribute(:description).collapse_spaces }

  it "should be valid with a name" do
    race = Race.create!(name: 'Slow Mo 100')

    expect(Race.all.count).to(equal(1))
    expect(race).to be_valid
  end

  it "should be invalid without a name" do
    race = Race.new(name: nil)
    expect(race).not_to be_valid
    expect(race.errors[:name]).to include("can't be blank")
  end

  it "should not allow duplicate names" do
    Race.create!(name: 'Hard Time 100')
    race = Race.new(name: 'Hard Time 100')
    expect(race).not_to be_valid
    expect(race.errors[:name]).to include("has already been taken")
  end

end