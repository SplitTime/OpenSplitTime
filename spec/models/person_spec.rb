require 'rails_helper'

# t.string   "first_name",         limit: 32,                 null: false
# t.string   "last_name",          limit: 64,                 null: false
# t.integer  "gender",                                        null: false
# t.date     "birthdate"
# t.string   "city"
# t.string   "state_code"
# t.string   "email"
# t.string   "phone"
# t.string   "country_code",       limit: 2
# t.integer  "user_id"
# t.boolean  "concealed",                     default: false
# t.string   "photo_url"
# t.string   "slug",                                          null: false
# t.string   "topic_resource_key"

RSpec.describe Person, type: :model do
  it_behaves_like 'auditable'
  it { is_expected.to strip_attribute(:first_name).collapse_spaces }
  it { is_expected.to strip_attribute(:last_name).collapse_spaces }
  it { is_expected.to strip_attribute(:state_code).collapse_spaces }
  it { is_expected.to strip_attribute(:country_code).collapse_spaces }

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
    expect(person_2.errors[:birthdate]).to include("can't be in the future")
  end

  it 'permits plausible birthdates' do
    person = build_stubbed(:person, birthdate: '1977-01-01')
    expect(person).to be_valid
  end

  describe '#merge_with' do
    let(:course) { create(:course) }
    let(:event_1) { create(:event, course: course) }
    let(:event_2) { create(:event, course: course) }
    let(:event_3) { create(:event, course: course) }
    let(:person_1) { create(:person) }
    let(:person_2) { create(:person) }
    let!(:effort_1) { create(:effort, event: event_1, person: person_1) }
    let!(:effort_2) { create(:effort, event: event_2, person: person_1) }
    let!(:effort_3) { create(:effort, event: event_3, person: person_2) }

    it 'assigns efforts associated with the target to the surviving person' do
      person_2.merge_with(person_1)
      expect(person_2.efforts.count).to eq(3)
      expect(person_2.efforts).to include(effort_1)
      expect(person_2.efforts).to include(effort_2)
      expect(person_2.efforts).to include(effort_3)
    end

    it 'works in either direction' do
      person_1.merge_with(person_2)
      expect(person_1.efforts.count).to eq(3)
      expect(person_1.efforts).to include(effort_1)
      expect(person_1.efforts).to include(effort_2)
      expect(person_1.efforts).to include(effort_3)
    end

    it 'retains the subject person and destroys the target person' do
      person_2.merge_with(person_1)
      expect(Person.find_by(id: person_2.id)).to eq(person_2)
      expect(Person.find_by(id: person_1.id)).to be_nil
    end
  end

  describe '#associate_effort' do
    let(:event) { create(:event) }
    let(:person) { build(:person) }

    it 'upon successful save, associates the person with the pulled effort' do
      effort = create(:effort)
      person.associate_effort(effort)
      effort.reload
      expect(effort.person).to eq(person)
    end

    it 'returns false if person does not save' do
      effort = build(:effort, first_name: nil)
      expect(person.associate_effort(effort)).to be_falsey
    end

    it 'returns true if person saves' do
      effort = create(:effort)
      expect(person.associate_effort(effort)).to be_truthy
    end
  end

  describe '#should_be_concealed?' do
    let(:concealed_event) { build_stubbed(:event, concealed: true) }
    let(:visible_event) { build_stubbed(:event, concealed: false) }
    let(:concealed_effort) { build_stubbed(:effort, event: concealed_event) }
    let(:visible_effort) { build_stubbed(:effort, event: visible_event) }

    it 'returns true if all efforts associated with the person are concealed' do
      person = build_stubbed(:person, concealed: true, efforts: [concealed_effort])
      expect(person.should_be_concealed?).to eq(true)
    end

    it 'returns false if any efforts associated with the person are visible' do
      person = build_stubbed(:person, concealed: true, efforts: [concealed_effort, visible_effort])
      expect(person.should_be_concealed?).to eq(false)
    end

    it 'returns true if no efforts are associated with the person' do
      person = build_stubbed(:person, concealed: true, efforts: [])
      expect(person.should_be_concealed?).to eq(true)
    end
  end
end
