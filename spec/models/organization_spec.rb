require 'rails_helper'

# t.string   "name"
# t.string   "description"

RSpec.describe Organization, type: :model do
  it_behaves_like 'auditable'
  it { is_expected.to strip_attribute(:name).collapse_spaces }
  it { is_expected.to strip_attribute(:description).collapse_spaces }

  it 'is valid with a name' do
    organization = build_stubbed(:organization)

    expect(organization.name).to be_present
    expect(organization).to be_valid
  end

  it 'is invalid without a name' do
    organization = build_stubbed(:organization, name: nil)
    expect(organization).not_to be_valid
    expect(organization.errors[:name]).to include("can't be blank")
  end

  it 'does not allow duplicate names' do
    Organization.create!(name: 'Hard Time 100')
    organization = build_stubbed(:organization, name: 'Hard Time 100')
    expect(organization).not_to be_valid
    expect(organization.errors[:name]).to include('has already been taken')
  end

  describe '#should_be_concealed?' do
    let(:concealed_event_group) { create(:event_group, concealed: true) }
    let(:visible_event_group) { create(:event_group, concealed: false) }

    it 'returns true if all event_groups associated with the organization are concealed' do
      organization = build(:organization, concealed: false)
      concealed_event_group.update(organization: organization)
      organization.reload
      expect(organization.event_groups.size).to eq(1)
      expect(organization.should_be_concealed?).to eq(true)
    end

    it 'returns false if any event_groups associated with the organization are visible' do
      organization = build(:organization, concealed: true)
      visible_event_group.update(organization: organization)
      concealed_event_group.update(organization: organization)
      organization.reload
      expect(organization.event_groups.size).to eq(2)
      expect(organization.should_be_concealed?).to eq(false)
    end

    it 'returns true if no event_groups are associated with the organization' do
      organization = build(:organization, concealed: false)
      expect(organization.event_groups.size).to eq(0)
      expect(organization.should_be_concealed?).to eq(true)
    end
  end
end
