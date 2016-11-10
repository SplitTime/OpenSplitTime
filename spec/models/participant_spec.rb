require 'rails_helper'

# t.string   "first_name"
# t.string   "last_name"
# t.string   "gender"
# t.date     "birthdate"
# t.string   "city"
# t.string   "state_code"
# t.string  "country_code"
# t.string   "email"
# t.string   "phone"
# t.integer  "user_id"


RSpec.describe Participant, type: :model do
  it { is_expected.to strip_attribute(:first_name).collapse_spaces }
  it { is_expected.to strip_attribute(:last_name).collapse_spaces }
  it { is_expected.to strip_attribute(:state_code).collapse_spaces }
  it { is_expected.to strip_attribute(:country_code).collapse_spaces }

  it 'should be valid when created with a first_name, a last_name, and a gender' do
    participant = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')

    expect(Participant.all.count).to eq(1)
    expect(participant.first_name).to eq('Johnny')
    expect(participant.last_name).to eq('Appleseed')
    expect(participant.gender).to eq('male')
    expect(participant).to be_valid
  end

  it 'should be invalid without a first_name' do
    participant = Participant.new(first_name: nil, last_name: 'Appleseed', gender: 'male')
    expect(participant).not_to be_valid
    expect(participant.errors[:first_name]).to include("can't be blank")
  end

  it 'should be invalid without a last_name' do
    participant = Participant.new(first_name: 'Johnny', last_name: nil, gender: 'male')
    expect(participant).not_to be_valid
    expect(participant.errors[:last_name]).to include("can't be blank")
  end

  it 'should be invalid without a gender' do
    participant = Participant.new(first_name: 'Johnny', last_name: 'Appleseed', gender: nil)
    expect(participant).not_to be_valid
    expect(participant.errors[:gender]).to include("can't be blank")
  end

  it 'should reject invalid email' do
    participant1 = Participant.new(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', email: 'johnny@appleseed')
    participant2 = Participant.new(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', email: 'appleseed.com')
    participant3 = Participant.new(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', email: 'johnny@.com')
    participant4 = Participant.new(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', email: 'johnny')

    expect(participant1).not_to be_valid
    expect(participant2).not_to be_valid
    expect(participant3).not_to be_valid
    expect(participant4).not_to be_valid
  end

  describe 'merge_with' do
    let(:course) { Course.create!(name: 'Test Course 100') }
    let(:event1) { Event.create!(course: course, name: 'Test Event A', start_time: '2012-08-08 05:00:00') }
    let(:event2) { Event.create!(course: course, name: 'Test Event B', start_time: '2013-08-08 05:00:00') }
    let(:event3) { Event.create!(course: course, name: 'Test Event C', start_time: '2014-08-08 05:00:00') }
    let(:participant1) { Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01', country_code: 'US', state_code: 'CA') }
    let(:participant2) { Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01', country_code: nil, state_code: 'CA', city: 'Los Angeles') }

    it 'should assign efforts associated with the target to the surviving participant' do
      effort1 = Effort.create!(event: event1, participant: participant1, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
      effort2 = Effort.create!(event: event2, participant: participant1, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
      effort3 = Effort.create!(event: event3, participant: participant2, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
      participant2.merge_with(participant1)
      expect(participant2.efforts.count).to eq(3)
      expect(participant2.efforts).to include(effort1)
      expect(participant2.efforts).to include(effort2)
      expect(participant2.efforts).to include(effort3)
    end

    it 'should work in either direction' do
      effort1 = Effort.create!(event: event1, participant: participant1, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
      effort2 = Effort.create!(event: event2, participant: participant1, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
      effort3 = Effort.create!(event: event3, participant: participant2, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
      participant1.merge_with(participant2)
      expect(participant1.efforts.count).to eq(3)
      expect(participant1.efforts).to include(effort1)
      expect(participant1.efforts).to include(effort2)
      expect(participant1.efforts).to include(effort3)
    end

    it 'should destroy the target participant' do
      Effort.create!(event: event1, participant: participant1, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
      Effort.create!(event: event2, participant: participant1, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
      Effort.create!(event: event3, participant: participant2, first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')
      participant1_id = participant1.id
      participant2.merge_with(participant1)
      expect(Participant.where(id: participant1_id)).to eq([])
    end

  end

  describe 'associate_effort' do
    let(:course) { Course.create!(name: 'Test Course 100') }
    let(:event) { Event.create!(course: course, name: 'Test Event', start_time: '2012-08-08 05:00:00') }

    it 'upon successful save should associate the participant with the pulled effort' do
      participant = Participant.new
      effort = Effort.create!(event: event, bib_number: 99, city: 'Vancouver', birthdate: '1978-08-08',
                              state_code: 'BC', country_code: 'CA', age: 50,
                              first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      participant.associate_effort(effort)
      expect(effort.participant).to eq(participant)
    end

    it 'should return false if participant does not save' do
      participant = Participant.new
      effort = Effort.new(event: event, first_name: nil, last_name: nil, gender: 'female')
      expect(participant.associate_effort(effort)).to be_falsey
    end

    it 'should return true if participant saves' do
      participant = Participant.new
      effort = Effort.new(event: event, first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      expect(participant.associate_effort(effort)).to be_truthy
    end

  end
end