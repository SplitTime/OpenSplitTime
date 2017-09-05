require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe EffortAutoReconciler do
  let!(:event) { create(:event) }
  let!(:effort1) { create(:effort, event: event, person: nil, first_name: 'Jen', last_name: 'Abelman', gender: 'female', birthdate: '2004-10-10', state_code: 'CO', country_code: 'US') }
  let!(:effort2) { create(:effort, event: event, person: nil, first_name: 'John', last_name: 'Benenson', gender: 'male', birthdate: '2005-11-11', state_code: 'TX', country_code: 'US') }
  let!(:effort3) { create(:effort, event: event, person: nil, first_name: 'Jim', last_name: 'Carlson', gender: 'male') }
  let!(:effort4) { create(:effort, event: event, person: nil, first_name: 'Jane', last_name: 'Danielson', gender: 'female') }
  let!(:effort5) { create(:effort, event: event, person: nil, first_name: 'Joel', last_name: 'Eagleston', gender: 'male') }
  let!(:effort6) { create(:effort, event: event, person: nil, first_name: 'Julie', last_name: 'Fredrickson', gender: 'female') }
  let!(:effort7) { create(:effort, event: event, person: nil, first_name: 'Jerry', last_name: 'Gottfredson', gender: 'male') }
  let!(:effort8) { create(:effort, event: event, person: nil, first_name: 'Joe', last_name: 'Hendrickson', gender: 'male') }
  let!(:effort9) { create(:effort, event: event, person: nil, first_name: 'Jill', last_name: 'Isaacson', gender: 'female') }
  let!(:person1) { create(:person, first_name: 'Jen', last_name: 'Abelman', gender: 'female', birthdate: '2004-10-10', state_code: 'CO', country_code: 'US') }
  let!(:person2) { create(:person, first_name: 'John', last_name: 'Benenson', gender: 'male', birthdate: '2005-11-11', state_code: 'TX', country_code: 'US') }
  let!(:person3) { create(:person, first_name: 'Jimmy', last_name: 'Carlson', gender: 'male') }
  let!(:person4) { create(:person, first_name: 'Janey', last_name: 'Danielson', gender: 'female') }
  let!(:person5) { create(:person, first_name: 'Joel', last_name: 'Eagleston', gender: 'male') }

  subject { EffortAutoReconciler.new(event: event) }

  describe '#reconcile' do
    it 'creates new people for unmatched efforts' do
      subject.reconcile
      expect(Person.all.count).to eq(9)
    end

    it 'assigns unmatched efforts to newly created people' do
      subject.reconcile
      effort6 = Effort.find_by(last_name: 'Fredrickson')
      effort7 = Effort.find_by(last_name: 'Gottfredson')
      effort8 = Effort.find_by(last_name: 'Hendrickson')
      effort9 = Effort.find_by(last_name: 'Isaacson')
      person6 = Person.find_by(last_name: 'Fredrickson')
      person7 = Person.find_by(last_name: 'Gottfredson')
      person8 = Person.find_by(last_name: 'Hendrickson')
      person9 = Person.find_by(last_name: 'Isaacson')
      expect(effort6.person).to eq(person6)
      expect(effort7.person).to eq(person7)
      expect(effort8.person).to eq(person8)
      expect(effort9.person).to eq(person9)
    end

    it 'assigns exact matching efforts to existing people' do
      subject.reconcile
      effort1 = Effort.find_by(last_name: 'Abelman')
      effort2 = Effort.find_by(last_name: 'Benenson')
      expect(effort1.person).to eq(person1)
      expect(effort2.person).to eq(person2)
    end

    it 'does not assign close matching efforts to any person' do
      subject.reconcile
      effort3 = Effort.find_by(last_name: 'Carlson')
      effort4 = Effort.find_by(last_name: 'Danielson')
      effort5 = Effort.find_by(last_name: 'Eagleston')
      expect(effort3.person).to be_nil
      expect(effort4.person).to be_nil
      expect(effort5.person).to be_nil
    end

    describe '#report' do
      it 'produces an accurate report' do
        subject.reconcile
        expect(subject.report).to include('We found 2 people that matched our database.')
        expect(subject.report).to include('We created 4 people from efforts that had no close matches.')
        expect(subject.report).to include('We found 3 people that may or may not match our database.')
      end
    end
  end
end
