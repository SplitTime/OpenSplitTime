# frozen_string_literal: true

require 'rails_helper'

#   t.integer  "user_id"
#   t.integer  "person_id"
#   t.integer  "kind"

RSpec.describe Subscription, type: :model do
  subject(:subscription) { Subscription.new(user: user, person: person, protocol: protocol) }
  let(:user) { users(:admin_user) }
  let(:person) { people(:shatest_mortest) }
  let(:protocol) { :email }

  context 'when created with a user, and person, and a protocol' do
    it 'should be valid' do
      expect(subscription).to be_valid
      expect { subscription.save }.to change { Subscription.count }.by(1)
    end
  end

  context 'when created without a user' do
    let(:user) { nil }

    it 'should be invalid' do
      expect(subscription).not_to be_valid
      expect(subscription.errors[:user_id]).to include("can't be blank")
    end
  end

  context 'when created without a person' do
    let(:person) { nil }

    it 'should be invalid' do
      expect(subscription).not_to be_valid
      expect(subscription.errors[:person_id]).to include("can't be blank")
    end
  end
end
