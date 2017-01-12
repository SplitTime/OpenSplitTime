require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe EffortAutoReconciler do
  let(:course) { Course.create!(name: 'Test Course 100') }
  let(:event) { Event.create!(course: course, name: 'Test Event', start_time: '2012-08-08 05:00:00', laps_required: 1) }
  let!(:effort1) { Effort.create!(event: event, first_name: 'Jen', last_name: 'Abelman', gender: 'female', birthdate: '2004-10-10', state_code: 'CO', country_code: 'US') }
  let!(:effort2) { Effort.create!(event: event, first_name: 'John', last_name: 'Benenson', gender: 'male', birthdate: '2005-11-11', state_code: 'TX', country_code: 'US') }
  let!(:effort3) { Effort.create!(event: event, first_name: 'Jim', last_name: 'Carlson', gender: 'male') }
  let!(:effort4) { Effort.create!(event: event, first_name: 'Jane', last_name: 'Danielson', gender: 'female') }
  let!(:effort5) { Effort.create!(event: event, first_name: 'Joel', last_name: 'Eagleston', gender: 'male') }
  let!(:effort6) { Effort.create!(event: event, first_name: 'Julie', last_name: 'Fredrickson', gender: 'female') }
  let!(:effort7) { Effort.create!(event: event, first_name: 'Jerry', last_name: 'Gottfredson', gender: 'male') }
  let!(:effort8) { Effort.create!(event: event, first_name: 'Joe', last_name: 'Hendrickson', gender: 'male') }
  let!(:effort9) { Effort.create!(event: event, first_name: 'Jill', last_name: 'Isaacson', gender: 'female') }
  let!(:participant1) { Participant.create!(first_name: 'Jen', last_name: 'Abelman', gender: 'female', birthdate: '2004-10-10', state_code: 'CO', country_code: 'US') }
  let!(:participant2) { Participant.create!(first_name: 'John', last_name: 'Benenson', gender: 'male', birthdate: '2005-11-11', state_code: 'TX', country_code: 'US') }
  let!(:participant3) { Participant.create!(first_name: 'Jimmy', last_name: 'Carlson', gender: 'male') }
  let!(:participant4) { Participant.create!(first_name: 'Janey', last_name: 'Danielson', gender: 'female') }
  let!(:participant5) { Participant.create!(first_name: 'Joel', last_name: 'Eagleston', gender: 'male') }

  describe 'initialize' do
    it 'should create new participants for unmatched efforts' do
      EffortAutoReconciler.new(event)
      expect(Participant.all.count).to eq(9)
    end

    it 'should assign unmatched efforts to newly created participants' do
      EffortAutoReconciler.new(event)
      effort6 = Effort.find_by(last_name: 'Fredrickson')
      effort7 = Effort.find_by(last_name: 'Gottfredson')
      effort8 = Effort.find_by(last_name: 'Hendrickson')
      effort9 = Effort.find_by(last_name: 'Isaacson')
      participant6 = Participant.find_by(last_name: 'Fredrickson')
      participant7 = Participant.find_by(last_name: 'Gottfredson')
      participant8 = Participant.find_by(last_name: 'Hendrickson')
      participant9 = Participant.find_by(last_name: 'Isaacson')
      expect(effort6.participant).to eq(participant6)
      expect(effort7.participant).to eq(participant7)
      expect(effort8.participant).to eq(participant8)
      expect(effort9.participant).to eq(participant9)
    end

    it 'should assign exact matching efforts to existing participants' do
      EffortAutoReconciler.new(event)
      effort1 = Effort.find_by(last_name: 'Abelman')
      effort2 = Effort.find_by(last_name: 'Benenson')
      expect(effort1.participant).to eq(participant1)
      expect(effort2.participant).to eq(participant2)
    end

    it 'should not assign close matching efforts to any participant' do
      EffortAutoReconciler.new(event)
      effort3 = Effort.find_by(last_name: 'Carlson')
      effort4 = Effort.find_by(last_name: 'Danielson')
      effort5 = Effort.find_by(last_name: 'Eagleston')
      expect(effort3.participant).to be_nil
      expect(effort4.participant).to be_nil
      expect(effort5.participant).to be_nil
    end

    describe 'report' do
      it 'should produce an accurate report' do
        reconciler = EffortAutoReconciler.new(event)
        expect(reconciler.report).to include('We found 2 participants that matched our database.')
        expect(reconciler.report).to include('We created 4 participants from efforts that had no close matches.')
        expect(reconciler.report).to include('We found 3 participants that may or may not match our database.')
      end
    end
  end
end