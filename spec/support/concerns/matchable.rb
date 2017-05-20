shared_examples_for 'matchable' do
  let(:model) { described_class }

  describe '#possible_matching_participants' do
    it 'returns records for which first and last names match, regardless of middle name and regardless of other attributes' do
      subject_attributes = {first_name: 'Billy Bob', last_name: 'Williams'}
      matching_attributes = [{first_name: 'Billy Bob', last_name: 'Williams'}, {first_name: 'Billy', last_name: 'Bob Williams'}]
      differing_attributes = [{first_name: 'Joey', last_name: 'Jones'}, {first_name: 'Billy Bob', last_name: 'Jones'}]
      verify_matching_participants(subject_attributes, matching_attributes, differing_attributes)
    end

    it 'for female efforts, returns records for which first name, age, gender, and state are the same, but last name differs' do
      subject_attributes = {first_name: 'Jane', last_name: 'Jetson', gender: 'female', birthdate: '1967-07-01', state_code: 'CO'}
      matching_attributes = [{first_name: 'Jane', last_name: 'Goodall', gender: 'female', birthdate: '1967-07-01', state_code: 'CO'},
                             {first_name: 'Jane', last_name: 'Eyre', gender: 'female', birthdate: '1967-03-01', state_code: 'CO'}]
      differing_attributes = [{first_name: 'Betty', last_name: 'Boop', gender: 'female', birthdate: '1967-07-01', state_code: 'CO'},
                              {first_name: 'Jane', last_name: 'Goodall', gender: 'female', birthdate: '1999-07-01', state_code: 'CO'},
                              {first_name: 'Jane', last_name: 'Johnson', gender: 'female', birthdate: '1967-07-01', state_code: 'NM'}]
      verify_matching_participants(subject_attributes, matching_attributes, differing_attributes)
    end

    it 'for male efforts, does not return records for which first name, age, gender, and state are the same, but last name differs' do
      subject_attributes = {first_name: 'George', last_name: 'Jetson', gender: 'male', birthdate: '1967-07-01', state_code: 'CO'}
      matching_attributes = [{first_name: 'George', last_name: 'Jetson', gender: 'male', birthdate: '1967-07-01', state_code: 'CO'}]
      differing_attributes = [{first_name: 'George', last_name: 'Clooney', gender: 'male', birthdate: '1967-07-01', state_code: 'CO'}]
      verify_matching_participants(subject_attributes, matching_attributes, differing_attributes)
    end

    it 'returns records for which last name, age, and gender are the same, but first name differs' do
      subject_attributes = {first_name: 'Jane', last_name: 'Jetson', gender: 'female', birthdate: '1967-07-01'}
      matching_attributes = [{first_name: 'Judy', last_name: 'Jetson', gender: 'female', birthdate: '1967-07-01'},
                             {first_name: 'Jillian', last_name: 'Jetson', gender: 'female', birthdate: '1966-07-01'}]
      differing_attributes = [{first_name: 'Judy', last_name: 'Jetson', gender: 'female', birthdate: '2001-07-01'}]
      verify_matching_participants(subject_attributes, matching_attributes, differing_attributes)
    end

    def verify_matching_participants(subject_attributes, matching_attributes, differing_attributes)
      subject = described_class.new(subject_attributes)
      matching_participants = matching_attributes.map { |attribute_set| create(:participant, attribute_set) }
      differing_participants = differing_attributes.map { |attribute_set| create(:participant, attribute_set) }
      participants = subject.possible_matching_participants
      matching_participants.each { |matching_participant| expect(participants).to include(matching_participant) }
      differing_participants.each { |differing_participant| expect(participants).not_to include(differing_participant) }
    end
  end

  describe '#exact_matching_participant' do
    it 'returns a record for which first and last names and gender match, and either state_code or age matches' do
      subject_attributes = {first_name: 'Jane', last_name: 'Jetson', gender: 'female', birthdate: '1967-07-01', state_code: 'CO'}
      matching_attributes = subject_attributes
      differing_attributes = [{first_name: 'Jeanie', last_name: 'Jetson', gender: 'female', birthdate: '1967-07-01', state_code: 'CO'},
                              {first_name: 'Jane', last_name: 'Gleason', gender: 'female', birthdate: '1967-07-01', state_code: 'CO'},
                              {first_name: 'Jane', last_name: 'Jetson', gender: 'male', birthdate: '1967-07-01', state_code: 'CO'},
                              {first_name: 'Jane', last_name: 'Jetson', gender: 'female', birthdate: '1999-07-01', state_code: 'NM'}]
      verify_exact_matching_participant(subject_attributes, matching_attributes, differing_attributes)
    end

    it 'returns nil if more than one record is turned up' do
      subject_attributes = {first_name: 'Jane', last_name: 'Jetson', gender: 'female', birthdate: '1967-07-01', state_code: 'CO'}
      matching_attributes = nil
      differing_attributes = [{first_name: 'Jane', last_name: 'Jetson', gender: 'female', birthdate: '1967-07-01', state_code: 'NM'},
                              {first_name: 'Jane', last_name: 'Jetson', gender: 'female', birthdate: '1967-07-01', state_code: 'CO'}]
      verify_exact_matching_participant(subject_attributes, matching_attributes, differing_attributes)
    end

    def verify_exact_matching_participant(subject_attributes, matching_attributes, differing_attributes)
      subject = described_class.new(subject_attributes)
      matching_participant = matching_attributes ? create(:participant, matching_attributes) : nil
      differing_participants = differing_attributes.map { |attribute_set| create(:participant, attribute_set) }
      participant = subject.exact_matching_participant
      expect(participant).to eq(matching_participant)
      differing_participants.each { |differing_participant| expect(participant).not_to eq(differing_participant) }
    end
  end
end
