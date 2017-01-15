require 'rails_helper'

RSpec.describe LapSplit, type: :model do
  describe 'initialization' do
    it 'initializes with a lap and a split' do
      lap = 1
      split = FactoryGirl.build_stubbed(:split)
      expect { LapSplit.new(lap, split) }.not_to raise_error
    end
  end

  describe '#lap' do
    it 'returns the first value passed to the LapSplit at initialization' do
      lap = 1
      split = FactoryGirl.build_stubbed(:split)
      lap_split = LapSplit.new(lap, split)
      expect(lap_split.lap).to eq(lap)
    end
  end

  describe '#split' do
    it 'returns the second value passed to the LapSplit at initialization' do
      lap = 1
      split = FactoryGirl.build_stubbed(:split)
      lap_split = LapSplit.new(lap, split)
      expect(lap_split.split).to eq(split)
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

    it 'returns nil if split is not present' do
      lap = 1
      lap_split = LapSplit.new(lap, nil)
      expect(lap_split.time_point).to be_nil
    end

    it 'returns nil if split is present but has no id' do
      lap = 1
      split = FactoryGirl.build_stubbed(:split)
      split.id = nil
      lap_split = LapSplit.new(lap, split)
      expect(lap_split.time_point).to be_nil
    end
  end

  describe '#<=>' do
    let(:lap_1) { 1 }
    let(:lap_2) { 2 }
    let(:lap_3) { 3 }
    let(:split_1) { FactoryGirl.build_stubbed(:split, distance_from_start: 10000) }
    let(:split_2) { FactoryGirl.build_stubbed(:split, distance_from_start: 20000) }
    let(:split_3) { FactoryGirl.build_stubbed(:split, distance_from_start: 30000) }

    context 'when laps are different' do
      it 'treats a LapSplit with more laps as greater than the other LapSplits' do
        lap_split_1 = LapSplit.new(lap_3, split_1)
        lap_split_2 = LapSplit.new(lap_2, split_2)
        lap_split_3 = LapSplit.new(lap_2, split_3)

        expect(lap_split_1).to be > lap_split_2
        expect(lap_split_1).to be > lap_split_3
      end

      it 'treats a LapSplit with fewer laps as less than the other LapSplits' do
        lap_split_1 = LapSplit.new(lap_1, split_3)
        lap_split_2 = LapSplit.new(lap_2, split_2)
        lap_split_3 = LapSplit.new(lap_2, split_1)

        expect(lap_split_1).to be < lap_split_2
        expect(lap_split_1).to be < lap_split_3
      end
    end

    context 'when laps are the same' do
      it 'treats a LapSplit with longer split.distance_from_start as greater than the other LapSplits' do
        lap_split_1 = LapSplit.new(lap_1, split_3)
        lap_split_2 = LapSplit.new(lap_1, split_2)
        lap_split_3 = LapSplit.new(lap_1, split_1)

        expect(lap_split_1).to be > lap_split_2
        expect(lap_split_1).to be > lap_split_3
      end

      it 'treats a LapSplit with shorter split.distance_from_start as less than the other LapSplits' do
        lap_split_1 = LapSplit.new(lap_1, split_1)
        lap_split_2 = LapSplit.new(lap_1, split_2)
        lap_split_3 = LapSplit.new(lap_1, split_3)

        expect(lap_split_1).to be < lap_split_2
        expect(lap_split_1).to be < lap_split_3
      end

      it 'treats a LapSplit with the same split.distance_from_start as the same as the other LapSplits' do
        lap_split_1 = LapSplit.new(lap_1, split_2)
        lap_split_2 = LapSplit.new(lap_1, split_2)

        expect(lap_split_1).to be == lap_split_2
      end
    end
  end
end