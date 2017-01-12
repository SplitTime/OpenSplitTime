require 'rails_helper'

RSpec.describe TimePoint, type: :model do
  describe 'initialization' do
    it 'initializes with a split_id, a bitkey, and a lap' do
      split_id = 101
      bitkey = 64
      lap = 1
      expect { TimePoint.new(split_id, bitkey, lap) }.not_to raise_error
    end

    it 'initializes with a split_id and a bitkey, but no lap' do
      split_id = 101
      bitkey = 64
      expect { TimePoint.new(split_id, bitkey) }.not_to raise_error
    end
  end

  describe '#split_id' do
    it 'returns the first value passed to the TimePoint at initialization' do
      split_id = 101
      bitkey = 64
      lap = 1
      time_point = TimePoint.new(split_id, bitkey, lap)
      expect(time_point.split_id).to eq(split_id)
    end

    it 'returns nil if no value is given at initialization' do
      time_point = TimePoint.new
      expect(time_point.split_id).to be_nil
    end
  end

  describe '#bitkey' do
    it 'returns the second value passed to the TimePoint at initialization' do
      split_id = 101
      bitkey = 64
      lap = 1
      time_point = TimePoint.new(split_id, bitkey, lap)
      expect(time_point.bitkey).to eq(bitkey)
    end

    it 'returns nil if no value is given at initialization' do
      split_id = 101
      time_point = TimePoint.new(split_id)
      expect(time_point.bitkey).to be_nil
    end
  end

  describe '#lap' do
    it 'returns the third value passed to the TimePoint at initialization' do
      split_id = 101
      bitkey = 64
      lap = 1
      time_point = TimePoint.new(split_id, bitkey, lap)
      expect(time_point.lap).to eq(lap)
    end

    it 'returns nil if no value is given at initialization' do
      split_id = 101
      bitkey = 64
      time_point = TimePoint.new(split_id, bitkey)
      expect(time_point.lap).to be_nil
    end
  end

  describe '#sub_split' do
    it 'returns a sub_split hash using split_id and bitkey' do
      split_id = 101
      bitkey = 64
      lap = 1
      time_point = TimePoint.new(split_id, bitkey, lap)
      expect(time_point.sub_split).to eq({split_id => bitkey})
    end

    it 'returns nil if bitkey is not present' do
      split_id = 101
      lap = 1
      time_point = TimePoint.new(split_id, nil, lap)
      expect(time_point.sub_split).to be_nil
    end

    it 'returns nil if split_id is not present' do
      bitkey = 64
      lap = 1
      time_point = TimePoint.new(nil, bitkey, lap)
      expect(time_point.sub_split).to be_nil
    end
  end
end