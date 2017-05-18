shared_examples_for 'matchable' do
  let(:model) { described_class }

  describe '#possible_matching_participants' do

    it 'returns records for which first and last names match' do
      subject_attributes = {first_name: 'Bill', last_name: 'Williams', gender: 'male', state_code: 'CO'}
      matching_participant = create(:participant, first_name: 'Bill', last_name: 'Williams')
      differing_participant = create(:participant, first_name: 'Joe', last_name: 'Jones')
      verify_matching_participants(differing_participant, matching_participant, subject_attributes)
    end

    it 'for female efforts, returns records for which first name, age, and state is the same, but last name differs' do
      subject_attributes = {first_name: 'Jane', last_name: 'Jones', gender: 'female', state_code: 'CO'}
      matching_participant = create(:participant, first_name: 'Jane', last_name: 'Smith', state_code: 'CO')
      differing_participant = create(:participant, first_name: 'Betty', last_name: 'Jones', state_code: 'CO')
      verify_matching_participants(differing_participant, matching_participant, subject_attributes)
    end

    def verify_matching_participants(differing_participant, matching_participant, subject_attributes)
      subject = described_class.new(subject_attributes)
      allow(subject).to receive(:approximate_age_today).and_return(subject_attributes[:age])
      participants = subject.possible_matching_participants
      expect(participants).to include(matching_participant)
      expect(participants).not_to include(differing_participant)
    end
  end
end
