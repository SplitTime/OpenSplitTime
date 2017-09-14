require 'rails_helper'

describe String do
  describe '#numericize' do
    it 'converts a string containing numbers to a float' do
      expect('5050.50'.numericize).to eq(5050.5)
      expect('5050'.numericize).to eq(5050.0)
    end

    it 'removes commas and other non-numeric characters' do
      expect('14,000 feet'.numericize).to eq(14000)
      expect('$5.22'.numericize).to eq(5.22)
    end

    it 'returns 0.0 if no numeric content is contained' do
      expect('hello'.numericize).to eq(0.0)
    end
  end

  describe '#to_boolean' do
    it 'returns the TrueClass object when called on a true-ish string value' do
      true_strings = %w(1 t T true TRUE on ON).to_set
      true_strings.each do |string|
        expect(string.to_boolean).to eq(true)
      end
    end

    it 'returns the FalseClass object when called on a false-ish string value' do
      false_strings = %w(0 f F false FALSE off OFF).to_set
      false_strings.each do |string|
        expect(string.to_boolean).to eq(false)
      end
    end

    it 'returns nil when called on an empty string' do
      expect(''.to_boolean).to eq(nil)
    end

    it 'returns false when called on an unknown string value' do
      expect('hello'.to_boolean).to eq(true)
    end
  end

  describe '#phrase_in_common' do
    subject { string.phrase_in_common(other) }

    context 'when the two strings have one word in common at the start of the string' do
      let(:string) { 'hello world' }
      let(:other) { 'hello curl' }

      it 'returns the common word' do
        expect(subject).to eq('hello')
      end
    end

    context 'when the two strings have multiple words in common at the start of the string' do
      let(:string) { 'hello there world how are you?' }
      let(:other) { 'hello there world what is happening?' }

      it 'returns the common phrase' do
        expect(subject).to eq('hello there world')
      end
    end

    context 'when the two strings match but for inconsistent case' do
      let(:string) { 'Hello World' }
      let(:other) { 'hello world how are you'}
      
      it 'matches case-insensitive and returns the result using capitalization of the subject string' do
        expect(subject).to eq('Hello World')
      end
    end

    context 'when the two strings include a matching phrase at the end of the string' do
      let(:string) { 'Race of the Century' }
      let(:other) { 'Kids Race of the Century'}

      it 'returns the matching phrase' do
        expect(subject).to eq('Race of the Century')
      end
    end

    context 'when the two strings include a matching phrase in the middle of the string' do
      let(:string) { 'Adult Race of the Century Get Ready' }
      let(:other) { 'Kids Race of the Century They Are So Cute'}

      it 'returns the matching phrase' do
        expect(subject).to eq('Race of the Century')
      end
    end

    context 'when the two strings include numbers' do
      let(:string) { '2017 Rattlesnake Ramble' }
      let(:other) { '2017 Rattlesnake Ramble Kids Race'}

      it 'includes the numbers' do
        expect(subject).to eq('2017 Rattlesnake Ramble')
      end
    end

    context 'when the two strings include distance designations that differ' do
      let(:string) { '2017 Double Dirty 30 100K' }
      let(:other) { '2017 Double Dirty 30 55K'}

      it 'returns the expected result' do
        expect(subject).to eq('2017 Double Dirty 30')
      end
    end

    context 'when the longest matching phrase is in the middle between shorter matching phrases' do
      let(:string) { 'Hello world, please come to my house next week' }
      let(:other) { 'Hello friends, please come to my party next week' }

      it 'returns the longest matching phrase' do
        expect(subject).to eq('please come to my')
      end
    end

    context 'when the two strings have no words in common' do
      let(:string) { 'hello' }
      let(:other) { 'world' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when self is an empty string' do
      let(:string) { '' }
      let(:other) { 'hello world' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when other is an empty string' do
      let(:string) { 'hello world' }
      let(:other) { '' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when both subject and other are empty strings' do
      let(:string) { '' }
      let(:other) { '' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end

  describe '#uuid?' do
    it 'returns true when the object is a valid UUID v4' do
      expect(SecureRandom.uuid.uuid?).to eq(true)
    end

    it 'returns false when the object is not a valid UUID v4' do
      expect('Hello'.uuid?).to eq(false)
    end

    it 'returns false when the object is an empty string' do
      expect(''.uuid?).to eq(false)
    end
  end
end
