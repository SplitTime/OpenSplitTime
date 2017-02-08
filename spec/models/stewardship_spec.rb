require 'rails_helper'

#   t.integer  "user_id"
#   t.integer  "organization_id"
#   t.integer  "level"

RSpec.describe Stewardship, type: :model do
  it 'is valid when created with a user_id and a organization_id' do
    user = User.create!(first_name: 'Test', last_name: 'User', role: :user, email: 'user@example.com', password: 'password')
    organization = Organization.create!(name: 'Hardrock')
    stewardship = Stewardship.create!(user_id: user.id, organization_id: organization.id)

    expect(Stewardship.all.count).to(equal(1))
    expect(stewardship.user_id).to eq(user.id)
    expect(stewardship.organization_id).to eq(organization.id)
    expect(stewardship).to be_valid
  end

  it 'should be invalid without a user_id' do
    stewardship = Stewardship.new(user_id: nil, organization_id: 1)
    expect(stewardship).not_to be_valid
    expect(stewardship.errors[:user_id]).to include("can't be blank")
  end

  it 'should be invalid without an organization_id' do
    stewardship = Stewardship.new(user_id: 1, organization_id: nil)
    expect(stewardship).not_to be_valid
    expect(stewardship.errors[:organization_id]).to include("can't be blank")
  end
end