# frozen_string_literal: true

require 'rails_helper'
include BitkeyDefinitions

RSpec.describe LapSplit, type: :model do
  subject(:lap_split) { LapSplit.new(lap, split) }
  let(:lap) { 1 }
  let(:split) { Split.new }
  let(:start_split) { Split.new(id: 123, kind: :start, base_name: 'Test Start') }
  let(:intermediate_split) { Split.new(id: 123, kind: :intermediate, base_name: 'Test Aid Station', sub_split_bitmap: 65) }
  let(:bare_split_with_id) { Split.new(id: 123) }

  describe 'initialization' do
    it 'initializes with a lap and a split' do
      expect { lap_split }.not_to raise_error
    end
  end

  describe '#lap' do
    it 'returns the first value passed to the LapSplit at initialization' do
      expect(lap_split.lap).to eq(lap)
    end
  end

  describe '#split' do
    it 'returns the second value passed to the LapSplit at initialization' do
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
    let(:lap) { 1 }
    let(:split) { bare_split_with_id }

    it 'returns a LapSplitKey containing the split_id and lap number' do
      expect(lap_split.key).to eq(LapSplitKey.new(1, 123))
    end

    context 'if split_id is not present' do
      let(:lap) { 1 }
      let(:split) { Split.new }

      it 'returns nil' do
        expect(lap_split.key).to be_nil
      end
    end

    context 'if lap is not present' do
      let(:lap) { nil }
      let(:split) { bare_split_with_id }

      it 'returns nil' do
        expect(lap_split.key).to be_nil
      end
    end
  end

  describe '#names' do
    context 'if the split has one sub_split' do
      let(:split) { start_split }

      it 'returns the split name and lap number in an array' do
        expected = ['Test Start Lap 1']
        expect(lap_split.names).to eq(expected)
      end
    end

    context 'if the split has multiple sub_splits' do
      let(:split) { intermediate_split }

      it 'returns the split names with extensions and lap number in an array' do
        expected = ['Test Aid Station In Lap 1', 'Test Aid Station Out Lap 1']
        expect(lap_split.names).to eq(expected)
      end
    end
  end

  describe '#names_without_laps' do
    context 'if the split has one sub_split' do
      let(:split) { start_split }

      it 'returns the split name and lap number in an array' do
        expected = ['Test Start']
        expect(lap_split.names_without_laps).to eq(expected)
      end
    end

    context 'if the split has multiple sub_splits' do
      let(:split) { intermediate_split }

      it 'returns the split names with extensions and lap number in an array' do
        expected = ['Test Aid Station In', 'Test Aid Station Out']
        expect(lap_split.names_without_laps).to eq(expected)
      end
    end
  end

  describe '#name' do
    context 'if the split has one sub_split' do
      let(:split) { start_split }

      it 'returns the split name and lap number' do
        expected = 'Test Start Lap 1'
        expect(lap_split.name).to eq(expected)
      end
    end

    context 'if the split has multiple sub_splits' do
      let(:split) { intermediate_split }

      it 'returns the split name with extensions and lap number' do
        expected = 'Test Aid Station In / Out Lap 1'
        expect(lap_split.name).to eq(expected)
      end
    end

    context 'if a bitkey is provided' do
      let(:split) { intermediate_split }

      it 'returns the split name with the related extension and the lap number' do
        expected = 'Test Aid Station Out Lap 1'
        expect(lap_split.name(out_bitkey)).to eq(expected)
      end
    end

    context 'if lap is not present' do
      let(:lap) { nil }
      let(:split) { intermediate_split }

      it 'returns the split name plus "[unknown lap]"' do
        expected = 'Test Aid Station In / Out [unknown lap]'
        expect(lap_split.name).to eq(expected)
      end
    end

    context 'if split is not present' do
      let(:split) { nil }

      it 'returns "[unknown split]" plus the lap number' do
        expected = '[unknown split] Lap 1'
        expect(lap_split.name).to eq(expected)
      end
    end
  end

  describe '#name_without_lap' do
    context 'if the split has one sub_split' do
      let(:split) { start_split }

      it 'returns the split name' do
        expected = 'Test Start'
        expect(lap_split.name_without_lap).to eq(expected)
      end
    end

    context 'if the split has multiple sub_splits' do
      let(:split) { intermediate_split }

      it 'returns the split name with extensions and lap number' do
        expected = 'Test Aid Station In / Out'
        expect(lap_split.name_without_lap).to eq(expected)
      end
    end

    context 'if a bitkey is provided' do
      let(:split) { intermediate_split }

      it 'returns the split name with the related extension' do
        expected = 'Test Aid Station Out'
        expect(lap_split.name_without_lap(out_bitkey)).to eq(expected)
      end
    end

    context 'if split is not present' do
      let(:split) { nil }

      it 'returns "[unknown split]" plus the lap number' do
        expected = '[unknown split]'
        expect(lap_split.name_without_lap).to eq(expected)
      end
    end
  end

  describe '#base_name' do
    context 'when lap and split are present' do
      let(:split) { intermediate_split }

      it 'returns a string containing the split name and lap number' do
        expected = 'Test Aid Station Lap 1'
        expect(lap_split.base_name).to eq(expected)
      end
    end

    context 'when lap is not present' do
      let(:split) { intermediate_split }
      let(:lap) { nil }

      it 'returns the split base_name plus "[unknown lap]"' do
        expect(lap_split.base_name).to eq('Test Aid Station [unknown lap]')
      end
    end

    context 'if split is not present' do
      let(:split) { nil }

      it 'returns "[unknown split]" plus the lap number' do
        expect(lap_split.base_name).to eq('[unknown split] Lap 1')
      end
    end
  end

  describe '#base_name_without_lap' do
    context 'when lap and split are present' do
      let(:split) { intermediate_split }

      it 'returns a string containing the split name and lap number' do
        expected = 'Test Aid Station'
        expect(lap_split.base_name_without_lap).to eq(expected)
      end
    end

    context 'when lap is not present' do
      let(:split) { intermediate_split }
      let(:lap) { nil }

      it 'returns the split base_name_without_lap' do
        expect(lap_split.base_name_without_lap).to eq('Test Aid Station')
      end
    end

    context 'if split is not present' do
      let(:split) { nil }

      it 'returns "[unknown split]"' do
        expect(lap_split.base_name_without_lap).to eq('[unknown split]')
      end
    end
  end

  describe '#time_points' do
    context 'for split with multiple bitkeys' do
      let(:split) { intermediate_split }

      it 'returns an array of TimePoints using the lap and split.id and all valid bitkeys' do
        expected = [TimePoint.new(lap, split.id, in_bitkey), TimePoint.new(lap, split.id, out_bitkey)]
        expect(lap_split.time_points).to eq(expected)
      end
    end

    context 'for a split with a single bitkey' do
      let(:split) { start_split }

      it 'returns an array of one TimePoint using the lap and split.id and bitkey' do
        expected = [TimePoint.new(lap, split.id, in_bitkey)]
        expect(lap_split.time_points).to eq(expected)
      end
    end

    context 'if split is not present' do
      let(:split) { nil }

      it 'returns nil' do
        expect(lap_split.time_points).to be_nil
      end
    end

    context 'if split is present but has no id' do
      let(:split) { Split.new }

      it 'returns nil' do
        expect(lap_split.time_points).to be_nil
      end
    end
  end

  describe '#time_point_in and #time_point_out' do
    context 'for a split with in and out bitkeys' do
      let(:split) { intermediate_split }

      it 'returns a TimePoint using the lap and split.id and an in or out bitkey' do
        expected_in = TimePoint.new(lap, split.id, in_bitkey)
        expected_out = TimePoint.new(lap, split.id, out_bitkey)
        expect(lap_split.time_point_in).to eq(expected_in)
        expect(lap_split.time_point_out).to eq(expected_out)
      end
    end

    context 'for a split with only an out bitkey' do
      let(:split) { Split.new(id: 123, sub_split_bitmap: SubSplit::OUT_BITKEY) }

      it 'returns nil for time_point_in and a TimePoint for time_point_out' do
        expect(lap_split.time_point_in).to be_nil
        expected_out = TimePoint.new(lap, split.id, out_bitkey)
        expect(lap_split.time_point_out).to eq(expected_out)
      end
    end

    context 'for a split with only an in bitkey' do
      let(:split) { start_split }

      it 'returns nil for time_point_out and a TimePoint for time_point_in' do
        expect(lap_split.time_point_out).to be_nil
        expected_in = TimePoint.new(lap, split.id, in_bitkey)
        expect(lap_split.time_point_in).to eq(expected_in)
      end
    end

    context 'if split is not present' do
      let(:split) { nil }

      it 'returns nil' do
        expect(lap_split.time_point_in).to be_nil
        expect(lap_split.time_point_out).to be_nil
      end
    end

    context 'if split is present but has no id' do
      let(:split) { Split.new }

      it 'returns nil' do
        expect(lap_split.time_point_in).to be_nil
        expect(lap_split.time_point_out).to be_nil
      end
    end
  end

  describe '#course' do
    subject { LapSplit.new(lap, split) }
    let(:lap) { 1 }
    let(:split) { course.ordered_splits.first }
    let(:course) { courses(:hardrock_counter_clockwise) }

    it 'returns the course to which split belongs' do
      expect(subject.course).to eq(course)
    end
  end

  describe '#distance_from_start' do
    subject { LapSplit.new(lap, split) }
    let(:splits) { course.ordered_splits }
    let(:course) { courses(:rufa_course) }
    let(:finish_split) { splits.last }
    let(:finish_split_distance) { finish_split.distance_from_start }
    let(:computed_distance) { finish_split_distance * (lap - 1) + split.distance_from_start }

    context 'for a start split on lap 1' do
      let(:lap) { 1 }
      let(:split) { splits.first }

      it 'returns 0' do
        expect(subject.distance_from_start).to eq(computed_distance)
      end
    end

    context 'for an intermediate or finish split on lap 1' do
      let(:lap) { 1 }
      let(:split) { splits.second }

      it 'returns a value equal to split.distance_from_start' do
        expect(subject.distance_from_start).to eq(computed_distance)
      end
    end

    context 'when lap is greater than 1' do
      let(:lap) { 2 }
      let(:split) { splits.second }

      it 'returns course length times finished laps plus split.distance_from_start' do
        expect(subject.distance_from_start).to eq(computed_distance)
      end
    end

    context 'over many laps with a partially completed lap' do
      let(:lap) { 4 }
      let(:split) { splits.third }

      it 'functions properly' do
        expect(subject.distance_from_start).to eq(computed_distance)
      end
    end

    context 'for many completed laps' do
      let(:lap) { 4 }
      let(:split) { finish_split }

      it 'functions properly' do
        expect(subject.distance_from_start).to eq(computed_distance)
      end
    end
  end

  describe '#vert_gain_from_start' do
    subject { LapSplit.new(lap, split) }
    let(:splits) { course.ordered_splits }
    let(:course) { courses(:rufa_course) }
    let(:finish_split) { splits.last }
    let(:finish_split_vert_gain) { finish_split.vert_gain_from_start }
    let(:computed_vert_gain) { finish_split_vert_gain * (lap - 1) + split.vert_gain_from_start }

    context 'for a start split on lap 1' do
      let(:lap) { 1 }
      let(:split) { splits.first }

      it 'returns 0' do
        expect(subject.vert_gain_from_start).to eq(computed_vert_gain)
      end
    end

    context 'for an intermediate or finish split on lap 1' do
      let(:lap) { 1 }
      let(:split) { splits.second }

      it 'returns a value equal to split.vert_gain_from_start' do
        expect(subject.vert_gain_from_start).to eq(computed_vert_gain)
      end
    end

    context 'when lap is greater than 1' do
      let(:lap) { 2 }
      let(:split) { splits.second }

      it 'returns course length times finished laps plus split.vert_gain_from_start' do
        expect(subject.vert_gain_from_start).to eq(computed_vert_gain)
      end
    end

    context 'over many laps with a partially completed lap' do
      let(:lap) { 4 }
      let(:split) { splits.third }

      it 'functions properly' do
        expect(subject.vert_gain_from_start).to eq(computed_vert_gain)
      end
    end

    context 'for many completed laps' do
      let(:lap) { 4 }
      let(:split) { finish_split }

      it 'functions properly' do
        expect(subject.vert_gain_from_start).to eq(computed_vert_gain)
      end
    end
  end

  describe '#vert_loss_from_start' do
    subject { LapSplit.new(lap, split) }
    let(:splits) { course.ordered_splits }
    let(:course) { courses(:rufa_course) }
    let(:finish_split) { splits.last }
    let(:finish_split_vert_loss) { finish_split.vert_loss_from_start }
    let(:computed_vert_loss) { finish_split_vert_loss * (lap - 1) + split.vert_loss_from_start }

    context 'for a start split on lap 1' do
      let(:lap) { 1 }
      let(:split) { splits.first }

      it 'returns 0' do
        expect(subject.vert_loss_from_start).to eq(computed_vert_loss)
      end
    end

    context 'for an intermediate or finish split on lap 1' do
      let(:lap) { 1 }
      let(:split) { splits.second }

      it 'returns a value equal to split.vert_loss_from_start' do
        expect(subject.vert_loss_from_start).to eq(computed_vert_loss)
      end
    end

    context 'when lap is greater than 1' do
      let(:lap) { 2 }
      let(:split) { splits.second }

      it 'returns course length times finished laps plus split.vert_loss_from_start' do
        expect(subject.vert_loss_from_start).to eq(computed_vert_loss)
      end
    end

    context 'over many laps with a partially completed lap' do
      let(:lap) { 4 }
      let(:split) { splits.third }

      it 'functions properly' do
        expect(subject.vert_loss_from_start).to eq(computed_vert_loss)
      end
    end

    context 'for many completed laps' do
      let(:lap) { 4 }
      let(:split) { finish_split }

      it 'functions properly' do
        expect(subject.vert_loss_from_start).to eq(computed_vert_loss)
      end
    end
  end

  describe '#start?' do
    let(:start_split) { build_stubbed(:split, :start) }
    let(:intermediate_split) { build_stubbed(:split) }

    context 'when split is a start split and lap == 1' do
      let(:split) { start_split }

      it 'returns true' do
        expect(lap_split).to be_start
      end
    end

    context 'when split is not a start split even if lap == 1' do
      let(:split) { intermediate_split }

      it 'returns false' do
        expect(lap_split).not_to be_start
      end
    end

    context 'when lap > 1 even if split is a start split' do
      let(:lap) { 2 }
      let(:split) { start_split }

      it 'returns false' do
        expect(lap_split).not_to be_start
      end
    end
  end
end
