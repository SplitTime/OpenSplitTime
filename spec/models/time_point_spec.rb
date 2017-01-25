require 'rails_helper'

RSpec.describe TimePoint, type: :model do
  describe 'initialization' do
    it 'initializes with a split_id, a bitkey, and a lap' do
      lap = 1
      split_id = 101
      bitkey = 64
      expect { TimePoint.new(lap, split_id, bitkey) }.not_to raise_error
    end

    it 'initializes with no arguments' do
      expect { TimePoint.new }.not_to raise_error
    end
  end

  describe '#==' do
    it 'equates time_points with identical lap, split_id, and bitkey' do
      lap = 1
      split_id = 101
      bitkey = 64
      lap_split_key_1 = TimePoint.new(lap, split_id, bitkey)
      lap_split_key_2 = TimePoint.new(lap, split_id, bitkey)
      expect(lap_split_key_1).to eq(lap_split_key_2)
    end

    it 'does not equate time_points with different laps' do
      lap_1 = 1
      lap_2 = 2
      split_id_1 = 101
      split_id_2 = 101
      bitkey_1 = 64
      bitkey_2 = 64
      time_point_1 = TimePoint.new(lap_1, split_id_1, bitkey_1)
      time_point_2 = TimePoint.new(lap_2, split_id_2, bitkey_2)
      expect(time_point_1).not_to eq(time_point_2)
    end

    it 'does not equate time_points with different split_ids' do
      lap_1 = 1
      lap_2 = 1
      split_id_1 = 101
      split_id_2 = 102
      bitkey_1 = 64
      bitkey_2 = 64
      time_point_1 = TimePoint.new(lap_1, split_id_1, bitkey_1)
      time_point_2 = TimePoint.new(lap_2, split_id_2, bitkey_2)
      expect(time_point_1).not_to eq(time_point_2)
    end

    it 'does not equate time_points with different bitkeys' do
      lap_1 = 1
      lap_2 = 1
      split_id_1 = 101
      split_id_2 = 101
      bitkey_1 = 1
      bitkey_2 = 64
      time_point_1 = TimePoint.new(lap_1, split_id_1, bitkey_1)
      time_point_2 = TimePoint.new(lap_2, split_id_2, bitkey_2)
      expect(time_point_1).not_to eq(time_point_2)
    end
  end

  describe '#lap' do
    it 'returns the first value passed to the TimePoint at initialization' do
      lap = 1
      split_id = 101
      bitkey = 64
      time_point = TimePoint.new(lap, split_id, bitkey)
      expect(time_point.lap).to eq(lap)
    end

    it 'returns nil if no value is given at initialization' do
      time_point = TimePoint.new
      expect(time_point.lap).to be_nil
    end
  end

  describe '#split_id' do
    it 'returns the second value passed to the TimePoint at initialization' do
      lap = 1
      split_id = 101
      bitkey = 64
      time_point = TimePoint.new(lap, split_id, bitkey)
      expect(time_point.split_id).to eq(split_id)
    end

    it 'returns nil if no value is given at initialization' do
      time_point = TimePoint.new
      expect(time_point.split_id).to be_nil
    end
  end

  describe '#bitkey' do
    it 'returns the third value passed to the TimePoint at initialization' do
      lap = 1
      split_id = 101
      bitkey = 64
      time_point = TimePoint.new(lap, split_id, bitkey)
      expect(time_point.bitkey).to eq(bitkey)
    end

    it 'returns nil if no value is given at initialization' do
      time_point = TimePoint.new
      expect(time_point.bitkey).to be_nil
    end
  end

  describe '#sub_split' do
    it 'returns a sub_split hash using split_id and bitkey' do
      lap = 1
      split_id = 101
      bitkey = 64
      time_point = TimePoint.new(lap, split_id, bitkey)
      expect(time_point.sub_split).to eq({split_id => bitkey})
    end

    it 'returns nil if bitkey is not present' do
      lap = 1
      split_id = 101
      time_point = TimePoint.new(lap, split_id)
      expect(time_point.sub_split).to be_nil
    end

    it 'returns nil if split_id is not present' do
      lap = 1
      bitkey = 64
      time_point = TimePoint.new(lap, nil, bitkey)
      expect(time_point.sub_split).to be_nil
    end
  end

  describe '#lap_split_key' do
    it 'returns a lap_split_key using lap and split_id' do
      lap = 1
      split_id = 101
      bitkey = 64
      time_point = TimePoint.new(lap, split_id, bitkey)
      expect(time_point.lap_split_key).to eq(LapSplitKey.new(lap, split_id))
    end

    it 'returns nil if lap is not present' do
      lap = nil
      split_id = 101
      bitkey = 64
      time_point = TimePoint.new(lap, split_id, bitkey)
      expect(time_point.lap_split_key).to be_nil
    end

    it 'returns nil if split_id is not present' do
      lap = 1
      split_id = nil
      bitkey = 64
      time_point = TimePoint.new(lap, split_id, bitkey)
      expect(time_point.lap_split_key).to be_nil
    end
  end

  describe '#kind' do
    it 'returns "In" or "Out" based on bitkey' do
      lap = 1
      split_id = 101
      bitkey = 64
      time_point = TimePoint.new(lap, split_id, bitkey)
      expect(time_point.kind).to eq('Out')
      time_point.bitkey = 1
      expect(time_point.kind).to eq('In')
    end

    it 'returns nil if bitkey is not present' do
      lap = 1
      split_id = 101
      bitkey = nil
      time_point = TimePoint.new(lap, split_id, bitkey)
      expect(time_point.kind).to be_nil
    end
  end
end