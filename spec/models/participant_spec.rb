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

RSpec.describe Participant, type: :model do
  it_behaves_like 'auditable'
  it { is_expected.to strip_attribute(:first_name).collapse_spaces }
  it { is_expected.to strip_attribute(:last_name).collapse_spaces }
  it { is_expected.to strip_attribute(:state_code).collapse_spaces }
  it { is_expected.to strip_attribute(:country_code).collapse_spaces }

  it 'is valid when created with a first_name, a last_name, and a gender' do
    participant = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')

    expect(Participant.all.count).to eq(1)
    expect(participant.first_name).to eq('Johnny')
    expect(participant.last_name).to eq('Appleseed')
    expect(participant.gender).to eq('male')
    expect(participant).to be_valid
  end

  it 'is invalid without a first_name' do
    participant = Participant.new(first_name: nil, last_name: 'Appleseed', gender: 'male')
    expect(participant).not_to be_valid
    expect(participant.errors[:first_name]).to include("can't be blank")
  end

  it 'is invalid without a last_name' do
    participant = Participant.new(first_name: 'Johnny', last_name: nil, gender: 'male')
    expect(participant).not_to be_valid
    expect(participant.errors[:last_name]).to include("can't be blank")
  end

  it 'is invalid without a gender' do
    participant = Participant.new(first_name: 'Johnny', last_name: 'Appleseed', gender: nil)
    expect(participant).not_to be_valid
    expect(participant.errors[:gender]).to include("can't be blank")
  end

  it 'rejects invalid email' do
    bad_emails = %w[johnny@appleseed appleseed.com johnny@.com johnny]
    bad_emails.each do |email|
      participant = build_stubbed(:participant, email: email)
      expect(participant).not_to be_valid
    end
  end

  it 'rejects implausible birthdates' do
    participant_1 = build_stubbed(:participant, birthdate: '1880-01-01')
    expect(participant_1).not_to be_valid
    expect(participant_1.errors[:birthdate]).to include("can't be before 1900")
    participant_2 = build_stubbed(:participant, birthdate: 1.day.from_now)
    expect(participant_2).not_to be_valid
    expect(participant_2.errors[:birthdate]).to include("can't be in the future")
  end

  it 'permits plausible birthdates' do
    participant = build_stubbed(:participant, birthdate: '1977-01-01')
    expect(participant).to be_valid
  end

  describe '#merge_with' do
    let(:course) { create(:course) }
    let(:event_1) { create(:event, course: course) }
    let(:event_2) { create(:event, course: course) }
    let(:event_3) { create(:event, course: course) }
    let(:participant_1) { create(:participant) }
    let(:participant_2) { create(:participant) }
    let!(:effort_1) { create(:effort, event: event_1, participant: participant_1) }
    let!(:effort_2) { create(:effort, event: event_2, participant: participant_1) }
    let!(:effort_3) { create(:effort, event: event_3, participant: participant_2) }

    it 'assigns efforts associated with the target to the surviving participant' do
      participant_2.merge_with(participant_1)
      expect(participant_2.efforts.count).to eq(3)
      expect(participant_2.efforts).to include(effort_1)
      expect(participant_2.efforts).to include(effort_2)
      expect(participant_2.efforts).to include(effort_3)
    end

    it 'works in either direction' do
      participant_1.merge_with(participant_2)
      expect(participant_1.efforts.count).to eq(3)
      expect(participant_1.efforts).to include(effort_1)
      expect(participant_1.efforts).to include(effort_2)
      expect(participant_1.efforts).to include(effort_3)
    end

    it 'retains the subject participant and destroys the target participant' do
      participant_2.merge_with(participant_1)
      expect(Participant.find_by(id: participant_2.id)).to eq(participant_2)
      expect(Participant.find_by(id: participant_1.id)).to be_nil
    end
  end

  describe '#associate_effort' do
    let(:event) { create(:event) }
    let(:participant) { build(:participant) }

    it 'upon successful save, associates the participant with the pulled effort' do
      effort = create(:effort)
      participant.associate_effort(effort)
      effort.reload
      expect(effort.participant).to eq(participant)
    end

    it 'returns false if participant does not save' do
      effort = build(:effort, first_name: nil)
      expect(participant.associate_effort(effort)).to be_falsey
    end

    it 'returns true if participant saves' do
      effort = create(:effort)
      expect(participant.associate_effort(effort)).to be_truthy
    end
  end

  describe '#should_be_concealed?' do
    let(:concealed_effort) { create(:effort, concealed: true) }
    let(:visible_effort) { create(:effort, concealed: false) }

    it 'returns true if all efforts associated with the participant are concealed' do
      participant = create(:participant, concealed: false)
      concealed_effort.update(participant: participant)
      participant.reload
      expect(participant.efforts.size).to eq(1)
      expect(participant.should_be_concealed?).to eq(true)
    end

    it 'returns false if any efforts associated with the participant are visible' do
      participant = create(:participant, concealed: true)
      visible_effort.update(participant: participant)
      concealed_effort.update(participant: participant)
      participant.reload
      expect(participant.efforts.size).to eq(2)
      expect(participant.should_be_concealed?).to eq(false)
    end

    it 'returns true if no efforts are associated with the participant' do
      participant = create(:participant, concealed: false)
      expect(participant.efforts.size).to eq(0)
      expect(participant.should_be_concealed?).to eq(true)
    end
  end
end
