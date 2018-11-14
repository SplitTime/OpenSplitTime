# frozen_string_literal: true

require 'rails_helper'

#   t.integer  "user_id"
#   t.integer  "person_id"
#   t.integer  "kind"

RSpec.describe Subscription, type: :model do
  it 'should be valid when created with a user_id, a person_id, and a kind' do
    user = User.create!(first_name: 'Test', last_name: 'User', role: :user, email: 'user@example.com', password: 'password')
    person = Person.create!(first_name: 'Freddy', last_name: 'Fast', gender: 'male')
    subscription = Subscription.new(user_id: user.id, person_id: person.id, protocol: 'email')

    expect(subscription.user_id).to eq(user.id)
    expect(subscription.person_id).to eq(person.id)
    expect(subscription.protocol).to eq('email')
    expect(subscription).to be_valid
  end

  it 'should be invalid without a user_id' do
    subscription = Subscription.new(user_id: nil, person_id: 1)
    expect(subscription).not_to be_valid
    expect(subscription.errors[:user_id]).to include("can't be blank")
  end

  it 'should be invalid without a person_id' do
    subscription = Subscription.new(user_id: 1, person_id: nil)
    expect(subscription).not_to be_valid
    expect(subscription.errors[:person_id]).to include("can't be blank")
  end
end
