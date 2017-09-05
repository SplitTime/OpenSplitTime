require 'rails_helper'

RSpec.describe AttributePuller, type: :model do
  describe 'self.pull_attributes' do
    context 'when pulling geographical data' do

      it 'should pull country data from target when states match and country is nil' do
        person1 = create(:person, country_code: nil, state_code: 'CA')
        person2 = create(:person, country_code: 'US', state_code: 'CA')
        AttributePuller.pull_attributes!(person1, person2)
        person1.reload
        expect(person1.country_code).to eq('US')
      end

      it 'should not pull country data from target when puller state does not exist in country of target' do
        person1 = create(:person, country_code: nil, state_code: 'CA')
        person2 = create(:person, country_code: 'MX', state_code: nil)
        AttributePuller.pull_attributes!(person1, person2)
        person1.reload
        expect(person1.country_code).to be_nil
      end

      it 'should not pull state data from target when target state does not exist in country of puller' do
        person1 = create(:person, country_code: 'US', state_code: nil)
        person2 = create(:person, country_code: 'CA', state_code: 'BC')
        AttributePuller.pull_attributes!(person1, person2)
        person1.reload
        expect(person1.state_code).to be_nil
      end

      it 'should not pull country, state, or city data from target when a country conflict exists' do
        person1 = create(:person, country_code: 'MX', state_code: nil, city: nil)
        person2 = create(:person, country_code: 'US', state_code: 'CO', city: 'Denver')
        person1.merge_with(person2)
        person1.reload
        expect(person1.country_code).to eq('MX')
        expect(person1.state_code).to eq(nil)
        expect(person1.city).to eq(nil)
      end

      it 'should not pull state or city data from target when a state conflict exists' do
        person1 = create(:person, country_code: 'US', state_code: 'CA', city: nil)
        person2 = create(:person, country_code: 'US', state_code: 'CO', city: 'Denver')
        AttributePuller.pull_attributes!(person1, person2)
        person1.reload
        expect(person1.state_code).to eq('CA')
        expect(person1.city).to be_nil
      end

      it 'should not pull city data from target when a city conflict exists' do
        person1 = create(:person, country_code: 'US', state_code: 'CO', city: 'Grand Junction')
        person2 = create(:person, country_code: 'US', state_code: 'CO', city: 'Denver')
        AttributePuller.pull_attributes!(person1, person2)
        person1.reload
        expect(person1.city).to eq('Grand Junction')
      end

      it 'should pull city data when country is the same and target state is nil' do
        person1 = create(:person, country_code: 'US', state_code: 'CO', city: nil)
        person2 = create(:person, country_code: 'US', state_code: nil, city: 'Denver')
        AttributePuller.pull_attributes!(person1, person2)
        person1.reload
        expect(person1.city).to eq('Denver')
      end

      it 'should pull city data when state is the same and target country is nil' do
        person1 = create(:person, country_code: 'US', state_code: 'CA', city: nil)
        person2 = create(:person, country_code: nil, state_code: 'CA', city: 'Los Angeles')
        AttributePuller.pull_attributes!(person1, person2)
        person1.reload
        expect(person1.city).to eq('Los Angeles')
      end

      it 'should pull city data when state and country are the same and city is nil' do
        person1 = create(:person, country_code: 'US', state_code: 'CO', city: nil)
        person2 = create(:person, country_code: 'US', state_code: 'CO', city: 'Grand Junction')
        AttributePuller.pull_attributes!(person1, person2)
        person1.reload
        expect(person1.city).to eq('Grand Junction')
      end

      it 'should pull country, state, and city data when all three are nil' do
        person1 = create(:person, country_code: nil, state_code: nil, city: nil)
        person2 = create(:person, country_code: 'US', state_code: 'CO', city: 'Grand Junction')
        AttributePuller.pull_attributes!(person1, person2)
        person1.reload
        expect(person1.country_code).to eq('US')
        expect(person1.state_code).to eq('CO')
        expect(person1.city).to eq('Grand Junction')
      end
    end

    context 'when pulling all available data' do
      let(:event) { build_stubbed(:event) }
      let(:effort) { build_stubbed(:effort, event: event, bib_number: 99, city: 'Vancouver', birthdate: '1978-08-08',
                                   state_code: 'BC', country_code: 'CA', age: 50,
                                   first_name: 'Jen', last_name: 'Huckster', gender: 'female', person_id: nil) }

      it 'should pull all target data into corresponding empty fields' do
        person = Person.new
        AttributePuller.pull_attributes!(person, effort)
        person.reload
        expect(person.first_name).to eq('Jen')
        expect(person.last_name).to eq('Huckster')
        expect(person.gender).to eq('female')
        expect(person.birthdate).to eq(Date.new(1978, 8, 8))
        expect(person.country_code).to eq('CA')
        expect(person.state_code).to eq('BC')
      end

      it 'should not pull target data into corresponding populated fields' do
        person = Person.new(birthdate: '1978-01-01', country_code: 'US',
                                      first_name: 'Jennifer', last_name: 'Huckster', gender: 'female')
        AttributePuller.pull_attributes!(person, effort)
        person.reload
        expect(person.first_name).to eq('Jennifer')
        expect(person.last_name).to eq('Huckster')
        expect(person.gender).to eq('female')
        expect(person.birthdate).to eq(Date.new(1978, 1, 1))
        expect(person.country_code).to eq('US')
      end

      it 'should not associate the puller with the target' do
        person = Person.new
        AttributePuller.pull_attributes!(person, effort)
        expect(effort.person_id).to be_nil
      end

      it 'should return false if puller does not save' do
        person = Person.new
        effort = Effort.new(event: event, first_name: nil, last_name: nil, gender: 'female')
        result = AttributePuller.pull_attributes!(person, effort)
        expect(result).to be_falsey
      end

      it 'should return true if puller saves' do
        person = Person.new
        effort = Effort.new(event: event, first_name: 'Jen', last_name: 'Huckster', gender: 'female')
        result = AttributePuller.pull_attributes!(person, effort)
        expect(result).to be_truthy
      end
    end
  end
end
