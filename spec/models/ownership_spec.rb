require 'rails_helper'

#   t.integer  "user_id"
#   t.integer  "race_id"
#   t.datetime "created_at", null: false
#   t.datetime "updated_at", null: false

RSpec.describe Ownership, type: :model do
  it "should have a user and a race" do
    user = User.create!(name: 'Test User', role: :user, email: 'user@example.com', password: 'password')
    race = Race.create!(name: 'Hardrock')
    Ownership.create!(user: user, race: race)

    expect(Ownership.all.count).to(equal(1))
    expect(Ownership.first.user_id).to eq(user.id)
    expect(Ownership.first.race_id).to eq(race.id)
  end
end
