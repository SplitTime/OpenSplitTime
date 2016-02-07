require 'rails_helper'

#   t.integer  "user_id"
#   t.integer  "participant_id"
#   t.integer  "kind"

RSpec.describe Interest, type: :model do
  it "should be valid when created with a user_id, a participant_id, and a kind" do
    user = User.create!(first_name: 'Test', last_name: 'User', role: :user, email: 'user@example.com', password: 'password')
    participant = Participant.create!(first_name: 'Freddy', last_name: 'Fast', gender: 'M')
    interest = Interest.create!(user_id: user.id, participant_id: participant.id, kind: 0)

    expect(Interest.all.count).to eq(1)
    expect(interest.user_id).to eq(user.id)
    expect(interest.participant_id).to eq(participant.id)
    expect(interest.kind).to eq('casual')
    expect(interest).to be_valid
  end

  it "should be invalid without a user_id" do
    interest = Interest.new(user_id: nil, participant_id: 1)
    interest.valid?
    expect(interest.errors[:user_id]).to include("can't be blank")
  end

  it "should be invalid without a participant_id" do
    interest = Interest.new(user_id: 1, participant_id: nil)
    interest.valid?
    expect(interest.errors[:participant_id]).to include("can't be blank")
  end

end
