# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Organization, type: :model do
  it_behaves_like 'auditable'
  it { is_expected.to strip_attribute(:name).collapse_spaces }
  it { is_expected.to strip_attribute(:description).collapse_spaces }

  describe '#initialize' do
    subject(:organization) { Organization.new(name: name) }

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
end
