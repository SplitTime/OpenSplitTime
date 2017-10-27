require 'rails_helper'

# t.string   "first_name",         limit: 32,                 null: false
# t.string   "last_name",          limit: 64,                 null: false
# t.integer  "gender",                                        null: false
# t.date     "birthdate"
# t.string   "city"
# t.string   "state_code"
# t.string   "email"
# t.string   "phone"
# t.datetime "created_at",                                    null: false
# t.datetime "updated_at",                                    null: false
# t.integer  "created_by"
# t.integer  "updated_by"
# t.string   "country_code",       limit: 2
# t.integer  "user_id"
# t.boolean  "concealed",                     default: false
# t.string   "slug",                                          null: false
# t.string   "topic_resource_key"
# t.string   "photo_file_name"
# t.string   "photo_content_type"
# t.integer  "photo_file_size"
# t.datetime "photo_updated_at"

RSpec.describe Person, type: :model do
  it_behaves_like 'auditable'
  it { is_expected.to strip_attribute(:first_name).collapse_spaces }
  it { is_expected.to strip_attribute(:last_name).collapse_spaces }
  it { is_expected.to strip_attribute(:state_code).collapse_spaces }
  it { is_expected.to strip_attribute(:country_code).collapse_spaces }

  it 'saves a generic factory-created record to the database' do
    person = create(:person)
    expect(Person.count).to eq(1)
    expect(Person.first).to eq(person)
  end

  it 'is valid when created with a first_name, a last_name, and a gender' do
    person = build_stubbed(:person)
    expect(person.first_name).to be_present
    expect(person.last_name).to be_present
    expect(person.gender).to be_present
    expect(person).to be_valid
  end

  it 'is invalid without a first_name' do
    person = build_stubbed(:person, first_name: nil)
    expect(person).not_to be_valid
    expect(person.errors[:first_name]).to include("can't be blank")
  end

  it 'is invalid without a last_name' do
    person = build_stubbed(:person, last_name: nil)
    expect(person).not_to be_valid
    expect(person.errors[:last_name]).to include("can't be blank")
  end

  it 'is invalid without a gender' do
    person = build_stubbed(:person, gender: nil)
    expect(person).not_to be_valid
    expect(person.errors[:gender]).to include("can't be blank")
  end

  it 'rejects invalid email' do
    bad_emails = %w[johnny@appleseed appleseed.com johnny@.com johnny]
    bad_emails.each do |email|
      person = build_stubbed(:person, email: email)
      expect(person).not_to be_valid
    end
  end

  it 'rejects implausible birthdates' do
    person_1 = build_stubbed(:person, birthdate: '1880-01-01')
    expect(person_1).not_to be_valid
    expect(person_1.errors[:birthdate]).to include("can't be before 1900")
    person_2 = build_stubbed(:person, birthdate: 1.day.from_now)
    expect(person_2).not_to be_valid
    expect(person_2.errors[:birthdate]).to include("can't be today or in the future")
  end

  it 'permits plausible birthdates' do
    person = build_stubbed(:person, birthdate: '1977-01-01')
    expect(person).to be_valid
  end

  describe '#should_be_concealed?' do
    let(:concealed_event_group) { create(:event_group, concealed: true) }
    let(:visible_event_group) { create(:event_group, concealed: false) }
    let(:concealed_event) { build_stubbed(:event, event_group: concealed_event_group) }
    let(:visible_event) { build_stubbed(:event, event_group: visible_event_group) }
    let(:concealed_effort) { build_stubbed(:effort, event: concealed_event) }
    let(:visible_effort) { build_stubbed(:effort, event: visible_event) }

    it 'returns true if all efforts associated with the person are concealed' do
      person = build_stubbed(:person, efforts: [concealed_effort])
      expect(person.should_be_concealed?).to eq(true)
    end

    it 'returns false if any efforts associated with the person are visible' do
      person = build_stubbed(:person, efforts: [concealed_effort, visible_effort])
      expect(person.should_be_concealed?).to eq(false)
    end

    it 'returns false if no efforts are associated with the person' do
      person = build_stubbed(:person, efforts: [])
      expect(person.should_be_concealed?).to eq(false)
    end
  end
end
