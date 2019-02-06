# frozen_string_literal: true

require 'rails_helper'

#   t.integer  "user_id"
#   t.integer  "person_id"
#   t.integer  "kind"

RSpec.describe Subscription, type: :model do
  subject(:subscription) { Subscription.new(user: user, subscribable: subscribable, protocol: protocol) }
  let(:user) { users(:admin_user) }
  let(:subscribable) { people(:tuan_jacobs) }
  let(:protocol) { :email }

  context 'when created with a user, a subscribable, and a protocol' do
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

  context 'when created without a subscribable' do
    let(:subscribable) { nil }

    it 'should be invalid' do
      expect(subscription).not_to be_valid
      expect(subscription.errors[:subscribable_id]).to include("can't be blank")
    end
  end
end
