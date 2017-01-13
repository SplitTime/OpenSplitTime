require 'rails_helper'

RSpec.describe LapSplit, type: :model do
  describe 'initialization' do
    it 'initializes with a lap and a split' do
      lap = 1
      split = FactoryGirl.build_stubbed(:split)
      expect { LapSplit.new(lap, split) }.not_to raise_error
    end

    it 'initializes with no arguments' do
      expect { LapSplit.new }.not_to raise_error
    end
  end

  describe '#lap' do
    it 'returns the first value passed to the LapSplit at initialization' do
      lap = 1
      split = FactoryGirl.build_stubbed(:split)
      lap_split = LapSplit.new(lap, split)
      expect(lap_split.lap).to eq(lap)
    end

    it 'returns nil if no value is given at initialization' do
      lap_split = LapSplit.new
      expect(lap_split.lap).to be_nil
    end
  end

  describe '#split' do
    it 'returns the second value passed to the LapSplit at initialization' do
      lap = 1
      split = FactoryGirl.build_stubbed(:split)
      lap_split = LapSplit.new(lap, split)
      expect(lap_split.split).to eq(split)
    end

    it 'returns nil if no value is given at initialization' do
      lap_split = LapSplit.new
      expect(lap_split.split).to be_nil
    end
  end

  describe '#name' do
    it 'returns a string containing the split name and lap number' do
      lap = 1
      split = FactoryGirl.build_stubbed(:split, base_name: 'Test Aid Station')
      lap_split = LapSplit.new(lap, split)
      expected = 'Test Aid Station Lap 1'
      expect(lap_split.name).to eq(expected)
    end

    it 'returns nil if lap is not present' do
      split = FactoryGirl.build_stubbed(:split, id: 123)
      lap_split = LapSplit.new(nil, split)
      expect(lap_split.name).to be_nil
    end

    it 'returns nil if split is not present' do
      lap = 1
      lap_split = LapSplit.new(lap, nil)
      expect(lap_split.name).to be_nil
    end
  end

  describe '#time_point' do
    it 'returns a TimePoint using the lap and split.id with no bitkey argument' do
      lap = 1
      split = FactoryGirl.build_stubbed(:split, id: 123)
      lap_split = LapSplit.new(lap, split)
      expected = TimePoint.new(lap, split.id)
      expect(lap_split.time_point).to eq(expected)
    end

    it 'returns nil if lap is not present' do
      split = FactoryGirl.build_stubbed(:split, id: 123)
      lap_split = LapSplit.new(nil, split)
      expect(lap_split.time_point).to be_nil
    end

    it 'returns nil if split is not present' do
      lap = 1
      lap_split = LapSplit.new(lap, nil)
      expect(lap_split.time_point).to be_nil
    end
  end
end