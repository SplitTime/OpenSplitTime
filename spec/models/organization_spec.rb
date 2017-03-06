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
end