require 'rails_helper'

RSpec.describe AttributePuller, type: :model do
  describe 'self.pull_attributes' do
    context 'when pulling geographical data' do

      it 'should pull country data from target when states match and country is nil' do
        participant1 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01', country_code: nil, state_code: 'CA', city: 'Los Angeles')
        participant2 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01', country_code: 'US', state_code: 'CA')
        AttributePuller.pull_attributes!(participant1, participant2)
        participant1.reload
        expect(participant1.country_code).to eq('US')
      end

      it 'should not pull country data from target when participant state does not exist in country of target' do
        participant1 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01', country_code: nil, state_code: 'CA', city: 'Los Angeles')
        participant2 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01', country_code: 'MX', state_code: nil)
        AttributePuller.pull_attributes!(participant1, participant2)
        participant1.reload
        expect(participant1.country_code).to be_nil
      end

      it 'should not pull state data from target when target state does not exist in country of participant' do
        participant1 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01', country_code: 'US', state_code: nil, city: 'Denver')
        participant2 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01', country_code: 'CA', state_code: 'BC')
        AttributePuller.pull_attributes!(participant1, participant2)
        participant1.reload
        expect(participant1.state_code).to be_nil
      end

      it 'should not pull country, state, or city data from target when a country conflict exists' do
        participant1 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01', country_code: 'US', state_code: 'CO', city: 'Denver')
        participant2 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01', country_code: 'MX', state_code: nil)
        participant2.merge_with(participant1)
        participant1.reload
        expect(participant2.country_code).to eq('MX')
        expect(participant2.state_code).to eq(nil)
        expect(participant2.city).to eq(nil)
      end

      it 'should not pull state or city data from target when a state conflict exists' do
        participant1 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01', country_code: 'US', state_code: 'CA')
        participant2 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01', country_code: 'US', state_code: 'CO', city: 'Denver')
        AttributePuller.pull_attributes!(participant1, participant2)
        participant1.reload
        expect(participant1.state_code).to eq('CA')
        expect(participant1.city).to be_nil
      end

      it 'should not pull city data from target when a city conflict exists' do
        participant1 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01', country_code: 'US', state_code: 'CO', city: 'Grand Junction')
        participant2 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01', country_code: 'US', state_code: 'CO', city: 'Denver')
        AttributePuller.pull_attributes!(participant1, participant2)
        participant1.reload
        expect(participant1.city).to eq('Grand Junction')
      end

      it 'should pull city data when country is the same and target state is nil' do
        participant1 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01', country_code: 'US', state_code: 'CO')
        participant2 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01', country_code: 'US', state_code: nil, city: 'Denver')
        AttributePuller.pull_attributes!(participant1, participant2)
        participant1.reload
        expect(participant1.city).to eq('Denver')
      end

      it 'should pull city data when state is the same and target country is nil' do
        participant1 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01', country_code: 'US', state_code: 'CA')
        participant2 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01', country_code: nil, state_code: 'CA', city: 'Los Angeles')
        AttributePuller.pull_attributes!(participant1, participant2)
        participant1.reload
        expect(participant1.city).to eq('Los Angeles')
      end

      it 'should pull city data when state and country are the same and city is nil' do
        participant1 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01', country_code: 'US', state_code: 'CO')
        participant2 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01', country_code: 'US', state_code: 'CO', city: 'Grand Junction')
        AttributePuller.pull_attributes!(participant1, participant2)
        participant1.reload
        expect(participant1.city).to eq('Grand Junction')
      end

      it 'should pull country, state, and city data when all three are nil' do
        participant1 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01')
        participant2 = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', birthdate: '1950-01-01', country_code: 'US', state_code: 'CO', city: 'Grand Junction')
        AttributePuller.pull_attributes!(participant1, participant2)
        participant1.reload
        expect(participant1.country_code).to eq('US')
        expect(participant1.state_code).to eq('CO')
        expect(participant1.city).to eq('Grand Junction')
      end
    end

    context 'when pulling all available data' do
      let(:course) { Course.create!(name: 'Test Course 100') }
      let(:event) { Event.create!(course: course, name: 'Test Event', start_time: '2012-08-08 05:00:00') }

      it 'should pull all effort data into corresponding empty fields' do
        participant = Participant.new
        effort = Effort.create!(event: event, bib_number: 99, city: 'Vancouver', birthdate: '1978-08-08',
                                state_code: 'BC', country_code: 'CA', age: 50,
                                first_name: 'Jen', last_name: 'Huckster', gender: 'female')
        AttributePuller.pull_attributes!(participant, effort)
        participant.reload
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
        AttributePuller.pull_attributes!(participant, effort)
        participant.reload
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
        AttributePuller.pull_attributes!(participant, effort)
        participant.reload
        expect(effort.participant).to eq(participant)
      end

      it 'should not pull state_code if country_code is different' do
        participant = Participant.new(birthdate: '1978-01-01', country_code: 'US',
                                      first_name: 'Jennifer', last_name: 'Huckster', gender: 'female')
        effort = Effort.create!(event: event, bib_number: 99, city: 'Vancouver', birthdate: '1978-08-08',
                                state_code: 'BC', country_code: 'CA', age: 50,
                                first_name: 'Jen', last_name: 'Huckster', gender: 'female')
        AttributePuller.pull_attributes!(participant, effort)
        participant.reload
        expect(participant.state_code).to be_nil
      end

      it 'should return false if participant does not save' do
        participant = Participant.new
        effort = Effort.new(event: event, first_name: nil, last_name: nil, gender: 'female')
        result = AttributePuller.pull_attributes!(participant, effort)
        expect(result).to be_falsey
      end

      it 'should return true if participant saves' do
        participant = Participant.new
        effort = Effort.new(event: event, first_name: 'Jen', last_name: 'Huckster', gender: 'female')
        result = AttributePuller.pull_attributes!(participant, effort)
        expect(result).to be_falsey
      end
    end
  end
end