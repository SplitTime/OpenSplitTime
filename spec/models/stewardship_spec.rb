# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Stewardship, type: :model do
  subject(:stewardship) { Stewardship.new(user: user, organization: organization) }
  let(:user) { users(:admin_user) }
  let(:organization) { organizations(:hardrock) }

  context 'when created with a user and a organization' do
    it 'is valid' do
      expect(stewardship).to be_valid
      expect { stewardship.save }.to change { Stewardship.count }.by(1)
    end
  end

  context 'when created without a user' do
    let(:user) { nil }

    it 'should be invalid' do
      expect(stewardship).not_to be_valid
      expect(stewardship.errors[:user]).to include("can't be blank")
    end
  end

  context 'when created without an organization' do
    let(:organization) { nil }

    it 'should be invalid without an organization_id' do
      expect(stewardship).not_to be_valid
      expect(stewardship.errors[:organization]).to include("can't be blank")
    end
  end
end
