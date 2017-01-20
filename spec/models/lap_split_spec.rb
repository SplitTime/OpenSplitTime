require 'rails_helper'

RSpec.describe LapSplit, type: :model do
  let(:in_bitkey) { SubSplit::IN_BITKEY }
  let(:out_bitkey) { SubSplit::OUT_BITKEY }

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

  describe '#time_points' do
    it 'for split with multiple bitkeys, returns an array of TimePoints using the lap and split.id and all valid bitkeys' do
      lap = 1
      split = FactoryGirl.build_stubbed(:split, id: 123)
      lap_split = LapSplit.new(lap, split)
      expected = [TimePoint.new(lap, split.id, in_bitkey), TimePoint.new(lap, split.id, out_bitkey)]
      expect(lap_split.time_points).to eq(expected)
    end

    it 'for a split with a single bitkey, returns an array of one TimePoint using the lap and split.id and bitkey' do
      lap = 1
      split = FactoryGirl.build_stubbed(:start_split, id: 123)
      lap_split = LapSplit.new(lap, split)
      expected = [TimePoint.new(lap, split.id, in_bitkey)]
      expect(lap_split.time_points).to eq(expected)
    end

    it 'returns nil if split is not present' do
      lap = 1
      lap_split = LapSplit.new(lap, nil)
      expect(lap_split.time_points).to be_nil
    end

    it 'returns nil if split is present but has no id' do
      lap = 1
      split = FactoryGirl.build_stubbed(:split)
      split.id = nil
      lap_split = LapSplit.new(lap, split)
      expect(lap_split.time_points).to be_nil
    end
  end

  describe '#<=>' do
    let(:lap_1) { 1 }
    let(:lap_2) { 2 }
    let(:lap_3) { 3 }
    let(:split_1) { FactoryGirl.build_stubbed(:start_split) }
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

  describe '#course' do
    it 'returns the course to which split belongs' do
      lap_1 = 1
      course = FactoryGirl.build_stubbed(:course_with_standard_splits, splits_count: 3)
      split = course.splits.first
      lap_split = LapSplit.new(lap_1, split)
      expect(lap_split.course).to eq(course)
    end
  end

  describe '#distance_from_start' do
    let(:lap_1) { 1 }
    let(:lap_2) { 2 }
    let(:lap_3) { 3 }
    let(:course_with_splits) { FactoryGirl.build_stubbed(:course_with_standard_splits, splits_count: 3) }
    let(:splits) { course_with_splits.splits }

    it 'returns 0 for a start split on lap 1' do
      course = course_with_splits
      split = splits.first
      allow(course).to receive(:distance).and_return(split.distance_from_start)
      lap_split = LapSplit.new(lap_1, split)
      expect(lap_split.distance_from_start).to eq(0)
    end

    it 'returns a value equal to split.distance_from_start when lap is 1' do
      course = course_with_splits
      split = splits.second
      allow(course).to receive(:distance).and_return(split.distance_from_start)
      lap_split = LapSplit.new(lap_1, split)
      expect(lap_split.distance_from_start).to eq(splits.second.distance_from_start)
    end

    it 'returns course length times finished laps plus split.distance_from_start when lap is greater than 1' do
      course = course_with_splits
      split = splits.second
      allow(course).to receive(:distance).and_return(split.distance_from_start)
      course_distance = course.distance
      lap_split = LapSplit.new(lap_2, split)
      expect(lap_split.distance_from_start).to eq(course_distance + splits.second.distance_from_start)
    end
  end
end