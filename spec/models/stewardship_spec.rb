require 'rails_helper'

#   t.integer  "user_id"
#   t.integer  "race_id"
#   t.integer  "level"

RSpec.describe Stewardship, type: :model do
  it "should be valid when created with a user_id and a race_id" do
    user = User.create!(first_name: 'Test', last_name: 'User', role: :user, email: 'user@example.com', password: 'password')
    race = Race.create!(name: 'Hardrock')
    stewardship = Stewardship.create!(user_id: user.id, race_id: race.id)

    expect(Stewardship.all.count).to(equal(1))
    expect(stewardship.user_id).to eq(user.id)
    expect(stewardship.race_id).to eq(race.id)
    expect(stewardship).to be_valid
  end

  it "should be invalid without a user_id" do
    stewardship = Stewardship.new(user_id: nil, race_id: 1)
    expect(stewardship).not_to be_valid
    expect(stewardship.errors[:user_id]).to include("can't be blank")
  end

  it "should be invalid without a race_id" do
    stewardship = Stewardship.new(user_id: 1, race_id: nil)
    expect(stewardship).not_to be_valid
    expect(stewardship.errors[:race_id]).to include("can't be blank")
  end

end
