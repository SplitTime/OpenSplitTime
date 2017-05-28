shared_examples_for 'transformable' do
  subject { described_class.new(attributes) }

  describe '#map_keys!' do
    context 'when all keys are in the object' do
      let(:attributes) { {name: 'Joe Hardman', sex: 'male'} }
      let(:map) { {name: :full_name, sex: :gender} }

      it 'changes keys according to the provided map' do
        subject.map_keys!(map)
        expect(subject.to_h.keys.sort).to eq([:full_name, :gender])
      end
    end

    context 'when some keys are not in the object' do
      let(:attributes) { {name: 'Joe Hardman', age: 29} }
      let(:map) { {name: :full_name, sex: :gender} }

      it 'ignores keys that are not found' do
        subject.map_keys!(map)
        expect(subject.to_h.keys.sort).to eq([:age, :full_name])
      end
    end
  end

  describe '#merge_attributes!' do
    let(:attributes) { {first_name: 'Joe', gender: 'male'} }

    context 'when merging attributes are disjoint from existing attributes' do
      let(:merging_attributes) { {last_name: 'Hardman', age: 55} }

      it 'merges existing attributes with merging attributes' do
        subject.merge_attributes!(merging_attributes)
        expect(subject.to_h).to eq({first_name: 'Joe', last_name: 'Hardman', gender: 'male', age: 55})
      end
    end

    context 'when merging attributes overlap with existing attributes' do
      let(:merging_attributes) { {first_name: 'Joseph', age: 55} }

      it 'gives precedence to merging attributes' do
        subject.merge_attributes!(merging_attributes)
        expect(subject.to_h).to eq({first_name: 'Joseph', gender: 'male', age: 55})
      end
    end
  end

  describe '#normalize_gender!' do
    context 'when existing gender starts with "M"' do
      let(:attributes) { {first_name: 'Joe', gender: 'M'} }

      it 'changes the value to "male"' do
        subject.normalize_gender!
        expect(subject.gender).to eq('male')
      end
    end

    context 'when existing gender does not start with "M"' do
      let(:attributes) { {first_name: 'Joe', gender: 'F'} }

      it 'changes the value to "female"' do
        subject.normalize_gender!
        expect(subject.gender).to eq('female')
      end
    end

    context 'when existing gender does not exist' do
      let(:attributes) { {first_name: 'Joe', age: 55} }

      it 'does not set a value' do
        subject.normalize_gender!
        expect(subject.gender).to eq(nil)
      end
    end
  end

  describe '#permit!' do
    let(:attributes) { {first_name: 'Joe', age: 55, role: 'admin'} }
    let(:permitted) { [:first_name, :last_name, :age] }

    it 'removes attributes that are not permitted' do
      subject.permit!(permitted)
      expect(subject.to_h).to eq({first_name: 'Joe', age: 55})
    end
  end

  describe '#split_field!' do
    let(:attributes) { {full_name: full_name} }

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
      subject.split_field!(:full_name, :first_name, :last_name)
      expect(subject.first_name).to eq(expected_first_name)
      expect(subject.last_name).to eq(expected_last_name)
    end
  end
end
