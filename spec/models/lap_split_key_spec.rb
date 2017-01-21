require 'rails_helper'

RSpec.describe LapSplitKey, type: :model do
  describe 'initialization' do
    it 'initializes with a lap and a split_id' do
      lap = 1
      split_id = 101
      expect { LapSplitKey.new(lap, split_id) }.not_to raise_error
    end

    it 'initializes with no arguments' do
      expect { LapSplitKey.new }.not_to raise_error
    end
  end

  describe '#==' do
    it 'equates lap_split_keys with identical lap and split_id' do
      lap = 1
      split_id = 101
      lap_split_key_1 = LapSplitKey.new(lap, split_id)
      lap_split_key_2 = LapSplitKey.new(lap, split_id)
      expect(lap_split_key_1).to eq(lap_split_key_2)
    end

    it 'does not equate lap_split_keys with different laps' do
      lap_1 = 1
      lap_2 = 2
      split_id_1 = 101
      split_id_2 = 101
      lap_split_key_1 = LapSplitKey.new(lap_1, split_id_1)
      lap_split_key_2 = LapSplitKey.new(lap_2, split_id_2)
      expect(lap_split_key_1).not_to eq(lap_split_key_2)
    end

    it 'does not equate lap_split_keys with different split_ids' do
      lap_1 = 1
      lap_2 = 1
      split_id_1 = 101
      split_id_2 = 102
      lap_split_key_1 = LapSplitKey.new(lap_1, split_id_1)
      lap_split_key_2 = LapSplitKey.new(lap_2, split_id_2)
      expect(lap_split_key_1).not_to eq(lap_split_key_2)
    end
  end

  describe '#lap' do
    it 'returns the first value passed to the TimePoint at initialization' do
      lap = 1
      split_id = 101
      lap_split_key = LapSplitKey.new(lap, split_id)
      expect(lap_split_key.lap).to eq(lap)
    end

    it 'returns nil if no value is given at initialization' do
      lap_split_key = LapSplitKey.new
      expect(lap_split_key.lap).to be_nil
    end
  end

  describe '#split_id' do
    it 'returns the second value passed to the TimePoint at initialization' do
      lap = 1
      split_id = 101
      lap_split_key = LapSplitKey.new(lap, split_id)
      expect(lap_split_key.split_id).to eq(split_id)
    end

    it 'returns nil if no value is given at initialization' do
      lap_split_key = LapSplitKey.new
      expect(lap_split_key.split_id).to be_nil
    end
  end
end