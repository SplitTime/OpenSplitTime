shared_examples_for 'data_status/transformable' do
  subject { described_class.new(parsed_structs, options) }
  let(:parsed_structs) { [struct] }
  let(:options) { {} }

  describe '#split_full_name!' do
    let(:struct) { OpenStruct.new(full_name: full_name) }

    context 'when full_name key contains a two-word name' do
      let(:full_name) { 'Joe Hardman' }

      it 'assigns the first word of the provided string to first_name and the last word to last_name' do
        expected_first_name = 'Joe'
        expected_last_name = 'Hardman'
        verify_split(expected_first_name, expected_last_name)
      end
    end

    context 'when provided with a three-word name' do
      let(:full_name) { 'Billy Bob Thornton' }

      it 'assigns the first two words of the provided string to first_name and the last word to last_name' do
        expected_first_name = 'Billy Bob'
        expected_last_name = 'Thornton'
        verify_split(expected_first_name, expected_last_name)
      end
    end

    context 'when provided with a one-word name' do
      let(:full_name) { 'Johnny' }

      it 'assigns the name to first_name' do
        expected_first_name = 'Johnny'
        expected_last_name = nil
        verify_split(expected_first_name, expected_last_name)
      end
    end

    context 'when provided with an empty string' do
      let(:full_name) { '' }

      it 'assigns nil to both first_name and last_name' do
        expected_first_name = nil
        expected_last_name = nil
        verify_split(expected_first_name, expected_last_name)
      end
    end

    context 'when provided with nil' do
      let(:full_name) { nil }

      it 'assigns nil to both first_name and last_name' do
        expected_first_name = nil
        expected_last_name = nil
        verify_split(expected_first_name, expected_last_name)
      end
    end

    def verify_split(expected_first_name, expected_last_name)
      structs = subject.split_full_name!
      subject_struct = structs.first
      expect(subject_struct.first_name).to eq(expected_first_name)
      expect(subject_struct.last_name).to eq(expected_last_name)
    end
  end
end
