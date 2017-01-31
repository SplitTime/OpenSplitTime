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
end