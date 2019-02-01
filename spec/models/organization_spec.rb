# frozen_string_literal: true

require 'rails_helper'

# t.string "name", limit: 64, null: false
# t.text "description"
# t.datetime "created_at", null: false
# t.datetime "updated_at", null: false
# t.integer "created_by"
# t.integer "updated_by"
# t.boolean "concealed", default: true
# t.string "slug", null: false

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

  describe '#should_be_concealed?' do
    let(:organization) { organizations(:hardrock) }

    context 'if all event_groups associated with the organization are concealed' do
      before { organization.event_groups.each { |eg| eg.update(concealed: true) } }

      it 'returns true' do
        expect(organization.should_be_concealed?).to eq(true)
      end
    end

    context 'if any event_groups associated with the organization are visible' do
      before do
        organization.event_groups.each { |eg| eg.update(concealed: true) }
        organization.event_groups.first.update(concealed: false)
      end

      it 'returns false' do
        expect(organization.should_be_concealed?).to eq(false)
      end
    end

    context 'if no event_groups are associated with the organization' do
      let(:organization) { create(:organization) }

      it 'returns true' do
        expect(organization.event_groups.size).to eq(0)
        expect(organization.should_be_concealed?).to eq(true)
      end
    end
  end
end
