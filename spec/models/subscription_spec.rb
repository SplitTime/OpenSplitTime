# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Subscription, type: :model do
  subject(:subscription) { Subscription.new(user: user, subscribable: subscribable, protocol: protocol) }
  let(:user) { users(:admin_user) }
  let(:subscribable) { people(:tuan_jacobs) }
  let(:protocol) { :email }

  context 'when created with a user, a subscribable, and a protocol' do
    it 'is valid' do
      expect(subscription).to be_valid
      expect { subscription.save }.to change { Subscription.count }.by(1)
    end
  end

  context 'when created without a user' do
    let(:user) { nil }

    it 'is invalid' do
      expect(subscription).not_to be_valid
      expect(subscription.errors[:user_id]).to include("can't be blank")
    end
  end

  context 'when created without a subscribable' do
    let(:subscribable) { nil }

    it 'is invalid' do
      expect(subscription).not_to be_valid
      expect(subscription.errors[:subscribable_id]).to include("can't be blank")
    end
  end

  context 'when created with ids instead of user and subscribable objects' do
    subject(:subscription) { Subscription.new(user_id: user_id, subscribable_type: subscribable_type,
                                              subscribable_id: subscribable_id, protocol: protocol) }
    let(:user_id) { user.id }
    let(:subscribable_type) { 'Person' }
    let(:subscribable_id) { subscribable.id }

    context 'when all ids are valid' do
      it 'is valid' do
        expect(subscription).to be_valid
      end
    end

    context 'when the user_id is invalid' do
      let(:user_id) { 0 }

      it 'is invalid' do
        expect(subscription).not_to be_valid
        expect(subscription.errors.full_messages).to include(/User can't be blank/)
      end
    end

    context 'when the subscribable_id is invalid' do
      let(:subscribable_id) { 0 }

      it 'is invalid' do
        expect(subscription).not_to be_valid
        expect(subscription.errors.full_messages).to include(/Subscribable can't be blank/)
      end
    end

    context 'when the subscribable_type is nil' do
      let(:subscribable_type) { nil }

      it 'is invalid' do
        expect(subscription).not_to be_valid
        expect(subscription.errors.full_messages).to include(/Subscribable can't be blank/)
      end
    end
  end
end
