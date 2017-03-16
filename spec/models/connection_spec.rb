require 'rails_helper'

#   t.integer  "user_id"
#   t.integer  "participant_id"
#   t.integer  "kind"

RSpec.describe Subscription, type: :model do
  it 'should be valid when created with a user_id, a participant_id, and a kind' do
    user = User.create!(first_name: 'Test', last_name: 'User', role: :user, email: 'user@example.com', password: 'password')
    participant = Participant.create!(first_name: 'Freddy', last_name: 'Fast', gender: 'male')
    subscription = Subscription.create!(user_id: user.id, participant_id: participant.id)

    expect(Subscription.all.count).to eq(1)
    expect(subscription.user_id).to eq(user.id)
    expect(subscription.participant_id).to eq(participant.id)
    expect(subscription.kind).to eq('casual')
    expect(subscription).to be_valid
  end

  it 'should be invalid without a user_id' do
    subscription = Subscription.new(user_id: nil, participant_id: 1)
    expect(subscription).not_to be_valid
    expect(subscription.errors[:user_id]).to include("can't be blank")
  end

  it 'should be invalid without a participant_id' do
    subscription = Subscription.new(user_id: 1, participant_id: nil)
    expect(subscription).not_to be_valid
    expect(subscription.errors[:participant_id]).to include("can't be blank")
  end
end
