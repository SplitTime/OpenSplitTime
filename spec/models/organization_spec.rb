# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Organization, type: :model do
  it_behaves_like 'auditable'
  it { is_expected.to strip_attribute(:name).collapse_spaces }
  it { is_expected.to strip_attribute(:description).collapse_spaces }
  subject(:organization) { described_class.new(name: name, owner_id: owner_id) }
  let(:name) { nil }
  let(:owner_id) { nil }

  describe '#initialize' do
    context 'when created with a unique name' do
      let(:name) { 'Test Organization' }
      it 'is valid' do
        expect(organization).to be_valid
      end
    end

    context 'without a name' do
      let(:name) { nil }
      it 'is invalid' do
        expect(organization).not_to be_valid
        expect(organization.errors[:name]).to include("can't be blank")
      end
    end

    context 'with a duplicate name' do
      let(:name) { 'Hardrock' }

      it 'is invalid' do
        expect(organization).not_to be_valid
        expect(organization.errors[:name]).to include('has already been taken')
      end
    end
  end

  describe '#owner_email' do
    context 'when the owner exists' do
      let(:owner_id) { owner.id }
      let(:owner) { users(:third_user) }
      it 'returns the email of the owner' do
        expect(subject.owner_email).to eq(owner.email)
      end
    end

    context 'when the owner does not exist' do
      before { allow(User).to receive(:find_by).and_return(nil) }
      it 'returns nil' do
        expect(subject.owner_email).to be_nil
      end
    end
  end

  describe '#owner_email=' do
    before { subject.owner_email = provided_email }
    context 'when the email exists' do
      let(:provided_email) { users(:third_user).email }
      it 'sets owner_id to the related user id' do
        expect(subject.owner_id).to eq(users(:third_user).id)
      end
    end

    context 'when the email does not exist' do
      let(:provided_email) { 'random@email.com' }
      it 'sets owner_id to nil' do
        expect(subject.owner_id).to be_nil
      end
    end

    context 'when the email provided is nil' do
      let(:provided_email) { nil }
      it 'sets owner_id to nil' do
        expect(subject.owner_id).to be_nil
      end
    end
  end
end
