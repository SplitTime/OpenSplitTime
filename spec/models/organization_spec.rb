require 'rails_helper'

# t.string   "name"
# t.string   "description"

RSpec.describe Organization, type: :model do
  it_behaves_like 'auditable'
  it { is_expected.to strip_attribute(:name).collapse_spaces }
  it { is_expected.to strip_attribute(:description).collapse_spaces }

  it 'is valid with a name' do
    organization = Organization.create!(name: 'Slow Mo 100')

    expect(Organization.all.count).to(equal(1))
    expect(organization).to be_valid
  end

  it 'is invalid without a name' do
    organization = Organization.new(name: nil)
    expect(organization).not_to be_valid
    expect(organization.errors[:name]).to include("can't be blank")
  end

  it 'does not allow duplicate names' do
    Organization.create!(name: 'Hard Time 100')
    organization = Organization.new(name: 'Hard Time 100')
    expect(organization).not_to be_valid
    expect(organization.errors[:name]).to include('has already been taken')
  end

  describe '#should_be_concealed?' do
    let(:concealed_event) { FactoryGirl.create(:event, concealed: true) }
    let(:visible_event) { FactoryGirl.create(:event, concealed: false) }

    it 'returns true if all events associated with the organization are concealed' do
      organization = FactoryGirl.create(:organization, concealed: false)
      concealed_event.update(organization: organization)
      organization.reload
      expect(organization.events.size).to eq(1)
      expect(organization.should_be_concealed?).to eq(true)
    end

    it 'returns false if any events associated with the organization are visible' do
      organization = FactoryGirl.create(:organization, concealed: true)
      visible_event.update(organization: organization)
      concealed_event.update(organization: organization)
      organization.reload
      expect(organization.events.size).to eq(2)
      expect(organization.should_be_concealed?).to eq(false)
    end

    it 'returns true if no events are associated with the organization' do
      organization = FactoryGirl.create(:organization, concealed: false)
      expect(organization.events.size).to eq(0)
      expect(organization.should_be_concealed?).to eq(true)
    end
  end
end