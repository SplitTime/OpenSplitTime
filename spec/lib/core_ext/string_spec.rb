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
