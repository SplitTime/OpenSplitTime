# frozen_string_literal: true

require_relative '../../../lib/core_ext/string'
require 'active_record'

RSpec.describe String do
  describe '.longest_common_phrase' do
    subject { String.longest_common_phrase(strings) }

    context 'when two strings have one word in common at the start of the string' do
      let(:strings) { ['hello world', 'hello curl'] }

      it 'returns the common word' do
        expect(subject).to eq('hello')
      end
    end

    context 'when two strings have multiple words in common at the start of the string' do
      let(:strings) { ['hello there world how are you?', 'hello there world what is happening?'] }

      it 'returns the common phrase' do
        expect(subject).to eq('hello there world')
      end
    end

    context 'when two strings match but for inconsistent case' do
      let(:strings) { ['Hello World', 'hello world how are you'] }

      it 'matches case-insensitive and returns a downcased result' do
        expect(subject).to eq('hello world')
      end
    end

    context 'when two strings include a matching phrase at the end of the string' do
      let(:strings) { ['Race of the Century', 'Kids Race of the Century'] }

      it 'returns the matching phrase' do
        expect(subject).to eq('race of the century')
      end
    end

    context 'when two strings include a matching phrase in the middle of the string' do
      let(:strings) { ['Adult Race of the Century Get Ready', 'Kids Race of the Century They Are So Cute'] }

      it 'returns the matching phrase' do
        expect(subject).to eq('race of the century')
      end
    end

    context 'when two strings include numbers' do
      let(:strings) { ['2017 Rattlesnake Ramble', '2017 Rattlesnake Ramble Kids Race'] }

      it 'includes the numbers' do
        expect(subject).to eq('2017 rattlesnake ramble')
      end
    end

    context 'when two strings include distance designations that differ' do
      let(:strings) { ['2017 Double Dirty 30 100K', '2017 Double Dirty 30 55K'] }

      it 'returns the expected result' do
        expect(subject).to eq('2017 double dirty 30')
      end
    end

    context 'when the longest matching phrase is in the middle between shorter matching phrases' do
      let(:strings) { ['Hello world, please come to my house next week', 'Hello friends, please come to my party next week'] }

      it 'returns the longest matching phrase' do
        expect(subject).to eq('please come to my')
      end
    end

    context 'when multiple strings are provided with a matching phrase' do
      let(:strings) { ['2017 Ramble Boys', '2017 Ramble Girls', '2017 Ramble Men', '2017 Ramble Women'] }

      it 'returns the common phrase' do
        expect(subject).to eq('2017 ramble')
      end
    end

    context 'when multiple strings are provided with imperfectly matching phrases' do
      let(:strings) { ['2017 Ramble Boys', '2017 Ramble Girls', 'Rattlesnake Ramble Men', 'Rattlesnake Ramble Women'] }

      it 'returns the only common phrase' do
        expect(subject).to eq('ramble')
      end
    end

    context 'when multiple strings are provided with no matching phrases' do
      let(:strings) { ['2017 Ramble Boys', '2017 Ramble Girls', 'Another Race'] }

      it 'returns the only common phrase' do
        expect(subject).to be_nil
      end
    end

    context 'when the two strings have no words in common' do
      let(:strings) { %w(hello world) }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when one string is an empty string' do
      let(:strings) { ['', 'hello world'] }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when all strings are empty strings' do
      let(:strings) { ['', ''] }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when only one string is given' do
      let(:strings) { ['Hello World'] }

      it 'returns a downcased version of the given string' do
        expect(subject).to eq('hello world')
      end
    end
  end

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
