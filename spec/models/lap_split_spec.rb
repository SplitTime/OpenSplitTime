# frozen_string_literal: true

require 'rails_helper'
include BitkeyDefinitions

RSpec.describe LapSplit, type: :model do
  describe 'initialization' do
    it 'initializes with a lap and a split' do
      lap = 1
      split = build_stubbed(:split)
      expect { LapSplit.new(lap, split) }.not_to raise_error
    end
  end

  describe '#lap' do
    it 'returns the first value passed to the LapSplit at initialization' do
      lap = 1
      split = build_stubbed(:split)
      lap_split = LapSplit.new(lap, split)
      expect(lap_split.lap).to eq(lap)
    end
  end

  describe '#split' do
    it 'returns the second value passed to the LapSplit at initialization' do
      lap = 1
      split = build_stubbed(:split)
      lap_split = LapSplit.new(lap, split)
      expect(lap_split.split).to eq(split)
    end
  end

  describe '#<=>' do
    let(:lap_1) { 1 }
    let(:lap_2) { 2 }
    let(:lap_3) { 3 }
    let(:split_1) { build_stubbed(:split, :start) }
    let(:split_2) { build_stubbed(:split, distance_from_start: 20000) }
    let(:split_3) { build_stubbed(:split, distance_from_start: 30000) }

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

    context 'when the comparison object is nil' do
      subject { LapSplit.new(lap_1, split_1) }
      let(:other) { nil }

      it 'does not equate the objects' do
        expect(subject == other).to eq(false)
        expect(other == subject).to eq(false)
      end
    end

    context 'when the comparison object is not a LapSplit' do
      subject { LapSplit.new(lap_1, split_1) }
      let(:other) { 'hello' }

      it 'does not equate the objects' do
        expect(subject == other).to eq(false)
        expect(other == subject).to eq(false)
      end
    end
  end

  describe '#key' do
    it 'returns a LapSplitKey containing the split_id and lap number' do
      lap = 1
      split = build_stubbed(:split, id: 123)
      lap_split = LapSplit.new(lap, split)
      expected = LapSplitKey.new(1, 123)
      expect(lap_split.key).to eq(expected)
    end

    it 'returns nil if split_id is not present' do
      lap = 1
      split = build_stubbed(:split)
      split.id = nil
      lap_split = LapSplit.new(lap, split)
      expect(lap_split.key).to be_nil
    end

    it 'returns nil if lap is not present' do
      split = build_stubbed(:split, id: 123)
      lap_split = LapSplit.new(nil, split)
      expect(lap_split.key).to be_nil
    end
  end

  describe '#names' do
    it 'returns the split name and lap number in an array if the split has one sub_split' do
      lap = 1
      split = build_stubbed(:split, :start, base_name: 'Test Start')
      lap_split = LapSplit.new(lap, split)
      expected = ['Test Start Lap 1']
      expect(lap_split.names).to eq(expected)
    end

    it 'returns the split names with extensions and lap number in an array if the split has multiple sub_splits' do
      lap = 1
      split = build_stubbed(:split, base_name: 'Test Aid Station')
      lap_split = LapSplit.new(lap, split)
      expected = ['Test Aid Station In Lap 1', 'Test Aid Station Out Lap 1']
      expect(lap_split.names).to eq(expected)
    end
  end

  describe '#names_without_laps' do
    it 'returns the split name in an array if the split has one sub_split' do
      lap = 1
      split = build_stubbed(:split, :start, base_name: 'Test Start')
      lap_split = LapSplit.new(lap, split)
      expected = ['Test Start']
      expect(lap_split.names_without_laps).to eq(expected)
    end

    it 'returns the split names with extensions in an array if the split has multiple sub_splits' do
      lap = 1
      split = build_stubbed(:split, base_name: 'Test Aid Station')
      lap_split = LapSplit.new(lap, split)
      expected = ['Test Aid Station In', 'Test Aid Station Out']
      expect(lap_split.names_without_laps).to eq(expected)
    end
  end

  describe '#name' do
    it 'returns the split name and lap number if the split has one sub_split' do
      lap = 1
      split = build_stubbed(:split, :start, base_name: 'Test Start')
      lap_split = LapSplit.new(lap, split)
      expected = 'Test Start Lap 1'
      expect(lap_split.name).to eq(expected)
    end

    it 'returns the split name with extensions and lap number if the split has multiple sub_splits' do
      lap = 1
      split = build_stubbed(:split, base_name: 'Test Aid Station')
      lap_split = LapSplit.new(lap, split)
      expected = 'Test Aid Station In / Out Lap 1'
      expect(lap_split.name).to eq(expected)
    end

    it 'returns the split name with the related extension and the lap number if a bitkey is provided' do
      lap = 1
      split = build_stubbed(:split, base_name: 'Test Aid Station')
      bitkey = out_bitkey
      lap_split = LapSplit.new(lap, split)
      expected = 'Test Aid Station Out Lap 1'
      expect(lap_split.name(bitkey)).to eq(expected)
    end

    it 'returns the split name plus "[unknown lap]" if lap is not present' do
      lap = nil
      split = build_stubbed(:split, base_name: 'Test Aid Station')
      lap_split = LapSplit.new(lap, split)
      expected = 'Test Aid Station In / Out [unknown lap]'
      expect(lap_split.name).to eq(expected)
    end

    it 'returns "[unknown split]" plus the lap number if split is not present' do
      lap = 1
      split = nil
      lap_split = LapSplit.new(lap, split)
      expected = '[unknown split] Lap 1'
      expect(lap_split.name).to eq(expected)
    end
  end

  describe '#name_without_lap' do
    it 'returns the split name if the split has one sub_split' do
      lap = 1
      split = build_stubbed(:split, :start, base_name: 'Test Start')
      expected = 'Test Start'
      lap_split = LapSplit.new(lap, split)
      expect(lap_split.name_without_lap).to eq(expected)
    end

    it 'returns the split name with extensions and lap number if the split has multiple sub_splits' do
      lap = 1
      split = build_stubbed(:split, base_name: 'Test Aid Station')
      lap_split = LapSplit.new(lap, split)
      expected = 'Test Aid Station In / Out'
      expect(lap_split.name_without_lap).to eq(expected)
    end

    it 'returns the split name with the related extension if a bitkey is provided' do
      lap = 1
      split = build_stubbed(:split, base_name: 'Test Aid Station')
      bitkey = out_bitkey
      lap_split = LapSplit.new(lap, split)
      expected = 'Test Aid Station Out'
      expect(lap_split.name_without_lap(bitkey)).to eq(expected)
    end

    it 'returns "[unknown split]" plus the lap number if split is not present' do
      lap = 1
      split = nil
      lap_split = LapSplit.new(lap, split)
      expected = '[unknown split]'
      expect(lap_split.name_without_lap).to eq(expected)
    end
  end

  describe '#base_name' do
    it 'returns a string containing the split name and lap number' do
      lap = 1
      split = build_stubbed(:split, base_name: 'Test Aid Station')
      lap_split = LapSplit.new(lap, split)
      expected = 'Test Aid Station Lap 1'
      expect(lap_split.base_name).to eq(expected)
    end

    it 'returns the split base_name plus "[unknown lap]" if lap is not present' do
      split = build_stubbed(:split, id: 123, base_name: 'Test Aid Station')
      lap_split = LapSplit.new(nil, split)
      expect(lap_split.base_name).to eq('Test Aid Station [unknown lap]')
    end

    it 'returns "[unknown split]" plus the lap number if split is not present' do
      lap = 1
      lap_split = LapSplit.new(lap, nil)
      expect(lap_split.base_name).to eq('[unknown split] Lap 1')
    end
  end

  describe '#base_name_without_lap' do
    it 'returns a string containing the split name' do
      lap = 1
      split = build_stubbed(:split, base_name: 'Test Aid Station')
      lap_split = LapSplit.new(lap, split)
      expected = 'Test Aid Station'
      expect(lap_split.base_name_without_lap).to eq(expected)
    end

    it 'returns a string containing the split name even if lap is not present' do
      split = build_stubbed(:split, base_name: 'Test Aid Station')
      lap_split = LapSplit.new(nil, split)
      expected = 'Test Aid Station'
      expect(lap_split.base_name_without_lap).to eq(expected)
    end

    it 'returns "[unknown split]" if split is not present' do
      lap = 1
      lap_split = LapSplit.new(lap, nil)
      expect(lap_split.base_name_without_lap).to eq('[unknown split]')
    end
  end

  describe '#time_points' do
    it 'for split with multiple bitkeys, returns an array of TimePoints using the lap and split.id and all valid bitkeys' do
      lap = 1
      split = build_stubbed(:split, id: 123)
      lap_split = LapSplit.new(lap, split)
      expected = [TimePoint.new(lap, split.id, in_bitkey), TimePoint.new(lap, split.id, out_bitkey)]
      expect(lap_split.time_points).to eq(expected)
    end

    it 'for a split with a single bitkey, returns an array of one TimePoint using the lap and split.id and bitkey' do
      lap = 1
      split = build_stubbed(:split, :start, id: 123)
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
      split = build_stubbed(:split)
      split.id = nil
      lap_split = LapSplit.new(lap, split)
      expect(lap_split.time_points).to be_nil
    end
  end

  describe '#time_point_in and #time_point_out' do
    it 'returns a TimePoint using the lap and split.id and an in or out bitkey' do
      lap = 1
      split = build_stubbed(:split, sub_split_bitmap: 65, id: 123)
      lap_split = LapSplit.new(lap, split)
      expected = TimePoint.new(lap, split.id, in_bitkey)
      expect(lap_split.time_point_in).to eq(expected)
      expected = TimePoint.new(lap, split.id, out_bitkey)
      expect(lap_split.time_point_out).to eq(expected)
    end

    it 'for a split with only an out bitkey, returns nil for time_point_in and a TimePoint for time_point_out' do
      lap = 1
      split = build_stubbed(:split, :start, sub_split_bitmap: 64, id: 123)
      lap_split = LapSplit.new(lap, split)
      expect(lap_split.time_point_in).to be_nil
      expected = TimePoint.new(lap, split.id, out_bitkey)
      expect(lap_split.time_point_out).to eq(expected)
    end

    it 'for a split with only an in bitkey, returns nil for time_point_out and a TimePoint for time_point_in' do
      lap = 1
      split = build_stubbed(:split, :start, sub_split_bitmap: 1, id: 123)
      lap_split = LapSplit.new(lap, split)
      expect(lap_split.time_point_out).to be_nil
      expected = TimePoint.new(lap, split.id, in_bitkey)
      expect(lap_split.time_point_in).to eq(expected)
    end

    it 'returns nil if split is not present' do
      lap = 1
      lap_split = LapSplit.new(lap, nil)
      expect(lap_split.time_point_in).to be_nil
      expect(lap_split.time_point_out).to be_nil
    end

    it 'returns nil if split is present but has no id' do
      lap = 1
      split = build_stubbed(:split)
      split.id = nil
      lap_split = LapSplit.new(lap, split)
      expect(lap_split.time_point_in).to be_nil
      expect(lap_split.time_point_out).to be_nil
    end
  end

  describe '#course' do
    it 'returns the course to which split belongs' do
      lap_1 = 1
      course = build_stubbed(:course_with_standard_splits, splits_count: 3)
      split = course.splits.first
      lap_split = LapSplit.new(lap_1, split)
      expect(lap_split.course).to eq(course)
    end
  end

  describe '#distance_from_start' do
    let(:course_with_splits) { build_stubbed(:course_with_standard_splits, splits_count: 4) }
    let(:splits) { course_with_splits.splits }

    it 'returns 0 for a start split on lap 1' do
      lap = 1
      split = splits.first
      expected = 0
      validate_distance(lap, split, expected)
    end

    it 'returns a value equal to split.distance_from_start when lap is 1' do
      lap = 1
      split = splits.second
      expected = splits.second.distance_from_start
      validate_distance(lap, split, expected)
    end

    it 'returns course length times finished laps plus split.distance_from_start when lap is greater than 1' do
      lap = 2
      split = splits.second
      expected = splits.last.distance_from_start + splits.second.distance_from_start
      validate_distance(lap, split, expected)
    end

    it 'functions properly over many laps with a partially completed lap' do
      lap = 4
      split = splits.third
      expected = splits.last.distance_from_start * 3 + splits.third.distance_from_start
      validate_distance(lap, split, expected)
    end

    it 'functions properly for many completed laps' do
      lap = 4
      split = splits.last
      expected = splits.last.distance_from_start * 4
      validate_distance(lap, split, expected)
    end

    def validate_distance(lap, split, expected)
      course = course_with_splits
      allow(course).to receive(:ordered_splits).and_return(splits)
      lap_split = LapSplit.new(lap, split)
      expect(lap_split.distance_from_start).to eq(expected)
    end
  end

  describe '#vert_gain_from_start' do
    let(:course_with_splits) { build_stubbed(:course_with_standard_splits, splits_count: 4) }
    let(:splits) { course_with_splits.splits }

    it 'returns 0 for a start split on lap 1' do
      lap = 1
      split = splits.first
      expected = 0
      validate_vert_gain(lap, split, expected)
    end

    it 'returns a value equal to split.vert_gain_from_start when lap is 1' do
      lap = 1
      split = splits.second
      expected = splits.second.vert_gain_from_start
      validate_vert_gain(lap, split, expected)
    end

    it 'returns course vert_gain times finished laps plus split.vert_gain_from_start when lap is greater than 1' do
      lap = 2
      split = splits.second
      expected = splits.last.vert_gain_from_start + splits.second.vert_gain_from_start
      validate_vert_gain(lap, split, expected)
    end

    it 'functions properly over many laps with a partially completed lap' do
      lap = 4
      split = splits.third
      expected = splits.last.vert_gain_from_start * 3 + splits.third.vert_gain_from_start
      validate_vert_gain(lap, split, expected)
    end

    it 'functions properly for many completed laps' do
      lap = 4
      split = splits.last
      expected = splits.last.vert_gain_from_start * 4
      validate_vert_gain(lap, split, expected)
    end

    def validate_vert_gain(lap, split, expected)
      course = course_with_splits
      allow(course).to receive(:ordered_splits).and_return(splits)
      lap_split = LapSplit.new(lap, split)
      expect(lap_split.vert_gain_from_start).to eq(expected)
    end
  end

  describe '#vert_loss_from_start' do
    let(:course_with_splits) { build_stubbed(:course_with_standard_splits, splits_count: 4) }
    let(:splits) { course_with_splits.splits }

    it 'returns 0 for a start split on lap 1' do
      lap = 1
      split = splits.first
      expected = 0
      validate_vert_loss(lap, split, expected)
    end

    it 'returns a value equal to split.vert_loss_from_start when lap is 1' do
      lap = 1
      split = splits.second
      expected = splits.second.vert_loss_from_start
      validate_vert_loss(lap, split, expected)
    end

    it 'returns course vert_loss times finished laps plus split.vert_loss_from_start when lap is greater than 1' do
      lap = 2
      split = splits.second
      expected = splits.last.vert_loss_from_start + splits.second.vert_loss_from_start
      validate_vert_loss(lap, split, expected)
    end

    it 'functions properly over many laps with a partially completed lap' do
      lap = 4
      split = splits.third
      expected = splits.last.vert_loss_from_start * 3 + splits.third.vert_loss_from_start
      validate_vert_loss(lap, split, expected)
    end

    it 'functions properly for many completed laps' do
      lap = 4
      split = splits.last
      expected = splits.last.vert_loss_from_start * 4
      validate_vert_loss(lap, split, expected)
    end

    def validate_vert_loss(lap, split, expected)
      course = course_with_splits
      allow(course).to receive(:ordered_splits).and_return(splits)
      lap_split = LapSplit.new(lap, split)
      expect(lap_split.vert_loss_from_start).to eq(expected)
    end
  end

  describe '#start?' do
    let(:start_split) { build_stubbed(:split, :start) }
    let(:intermediate_split) { build_stubbed(:split) }

    it 'returns true when split is a start split and lap == 1' do
      lap = 1
      split = start_split
      lap_split = LapSplit.new(lap, split)
      expect(lap_split.start?).to be_truthy
    end

    it 'returns false when split is not a start split even if lap == 1' do
      lap = 1
      split = intermediate_split
      lap_split = LapSplit.new(lap, split)
      expect(lap_split.start?).to be_falsey
    end

    it 'returns false when lap > 1 even if split is a start split' do
      lap = 2
      split = start_split
      lap_split = LapSplit.new(lap, split)
      expect(lap_split.start?).to be_falsey
    end
  end
end
