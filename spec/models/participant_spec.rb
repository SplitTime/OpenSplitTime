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
    before do
      @participant1 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01', country_code: 'US', state_code: 'CA')
      @participant2 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01', country_code: nil, state_code: 'CA', city: 'Los Angeles')
      @participant3 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01', country_code: 'US', state_code: 'CO', city: 'Denver')
      @participant4 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01', country_code: 'US', state_code: nil, city: 'Denver')
      @participant5 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01', country_code: 'MX', state_code: nil)
    end

    it 'should accept country data from target when states match' do
      @participant2.merge_with(@participant1)
      expect(@participant2.country_code).to eq('US')
    end

    it 'should not accept country data from target when state does not exist in country of target' do
      @participant2.merge_with(@participant5)
      expect(@participant2.country_code).to be_nil
    end

  end

  describe 'pull_data_from_effort' do
    let(:course) { Course.create!(name: 'Test Course 100') }
    let(:event) { Event.create!(course: course, name: 'Test Event', start_time: '2012-08-08 05:00:00') }

    it 'should pull all effort data into corresponding empty fields' do
      participant = Participant.new
      effort = Effort.create!(event: event, bib_number: 99, city: 'Vancouver', birthdate: '1978-08-08',
                                    state_code: 'BC', country_code: 'CA', age: 50,
                                    first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      participant.pull_data_from_effort(effort)
      expect(participant.first_name).to eq('Jen')
      expect(participant.last_name).to eq('Huckster')
      expect(participant.gender).to eq('female')
      expect(participant.birthdate).to eq(Date.new(1978, 8, 8))
      expect(participant.country_code).to eq('CA')
      expect(participant.state_code).to eq('BC')
    end

    it 'should not pull effort data into corresponding populated fields' do
      participant = Participant.new(birthdate: '1978-01-01', country_code: 'US',
                                    first_name: 'Jennifer', last_name: 'Huckster', gender: 'female')
      effort = Effort.create!(event: event, bib_number: 99, city: 'Vancouver', birthdate: '1978-08-08',
                              state_code: 'BC', country_code: 'CA', age: 50,
                              first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      participant.pull_data_from_effort(effort)
      expect(participant.first_name).to eq('Jennifer')
      expect(participant.last_name).to eq('Huckster')
      expect(participant.gender).to eq('female')
      expect(participant.birthdate).to eq(Date.new(1978, 1, 1))
      expect(participant.country_code).to eq('US')
    end

    it 'upon successful save should associate the participant with the pulled effort' do
      participant = Participant.new
      effort = Effort.create!(event: event, bib_number: 99, city: 'Vancouver', birthdate: '1978-08-08',
                              state_code: 'BC', country_code: 'CA', age: 50,
                              first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      participant.pull_data_from_effort(effort)
      expect(effort.participant).to eq(participant)
    end

    it 'should not pull state_code if country_code is different' do
      participant = Participant.new(birthdate: '1978-01-01', country_code: 'US',
                                    first_name: 'Jennifer', last_name: 'Huckster', gender: 'female')
      effort = Effort.create!(event: event, bib_number: 99, city: 'Vancouver', birthdate: '1978-08-08',
                              state_code: 'BC', country_code: 'CA', age: 50,
                              first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      participant.pull_data_from_effort(effort)
      expect(participant.state_code).to be_nil
    end

    it 'should return false if participant does not save' do
      participant = Participant.new
      effort = Effort.new(event: event, first_name: nil, last_name: nil, gender: 'female')
      expect(participant.pull_data_from_effort(effort)).to be_falsey
    end

    it 'should return true if participant saves' do
      participant = Participant.new
      effort = Effort.new(event: event, first_name: 'Jen', last_name: 'Huckster', gender: 'female')
      expect(participant.pull_data_from_effort(effort)).to be_truthy
    end

  end


end