require_relative '../../../lib/core_ext/numeric'

RSpec.describe Numeric do

  describe '#numericize' do
    it 'returns self without modification' do
      n = 123
      expect(n.numericize).to eq(n)
    end
  end

  describe '#round_to_nearest' do
    context 'when no argument is provided' do
      it 'returns the same number when called on an Integer' do
        n = 123
        expect(n.round_to_nearest).to eq(n)
      end

      it 'returns the number rounded to nearest integer when called on a Float' do
        n = 123.45
        x = 123.56
        expect(n.round_to_nearest).to eq(123)
        expect(x.round_to_nearest).to eq(124)
      end
    end

    context 'when the provided argument is a non-zero Integer' do
      it 'returns the Integer closest to self that is divisible by the argument when called on an Integer' do
        n = 57
        x = 58
        round_quotient = 5
        expect(n.round_to_nearest(round_quotient)).to eq(55)
        expect(x.round_to_nearest(round_quotient)).to eq(60)
      end

      it 'returns the Integer closest to self that is divisible by the argument when called on a Float' do
        n = 57.0
        x = 58.0
        round_quotient = 5
        expect(n.round_to_nearest(round_quotient)).to eq(55)
        expect(x.round_to_nearest(round_quotient)).to eq(60)
      end
    end

    context 'when the provided argument is a non-zero Float' do
      it 'returns the Integer closest to self that is divisible by the argument when called on an Integer' do
        n = 57
        x = 58
        round_quotient = 5
        expect(n.round_to_nearest(round_quotient)).to eq(55)
        expect(x.round_to_nearest(round_quotient)).to eq(60)
      end

      it 'returns the number closest to self that is divisible by the argument when called on a Float' do
        n = 57.3
        x = 58.2
        round_quotient = 0.5
        expect(n.round_to_nearest(round_quotient)).to eq(57.5)
        expect(x.round_to_nearest(round_quotient)).to eq(58.0)
      end
    end
  end
end
