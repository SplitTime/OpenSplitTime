require 'rails_helper'

RSpec.describe ExpectedLapFinder do
  let(:test_event) { build_stubbed(:event_functional, laps_required: 4, splits_count: 4, efforts_count: 1) }
  let(:test_splits) { test_event.splits }
  let(:test_effort) { test_event.efforts.first }
  let(:test_split_times) { test_effort.split_times }

  describe '#initialize' do
    it 'initializes with ordered_split_times and a split in an args hash' do
      split_times = test_split_times
      split = test_splits.last
      expect { ExpectedLapFinder.new(ordered_split_times: split_times,
                                     split: split) }.not_to raise_error
    end

    it 'raises an ArgumentError if no ordered_split_times are given' do
      split = test_splits.last
      expect { ExpectedLapFinder.new(split: split) }
          .to raise_error(/must include ordered_split_times/)
    end

    it 'raises an ArgumentError if no split is given' do
      split_times = test_split_times
      expect { ExpectedLapFinder.new(ordered_split_times: split_times) }
          .to raise_error(/must include split/)
    end
  end

  describe '#lap' do
    before do
      FactoryGirl.reload
    end

    it 'returns 1 when split_times are not present' do
      split_times = test_split_times.first(0)
      split = test_splits.first
      expected = 1
      validate_lap(split_times, split, expected)
    end

    it 'returns 1 when split_times are present but none exist for the specified split' do
      split_times = test_split_times.first(3) # Start and Aid 1 (in/out)
      split = test_splits.third # Aid 2
      expected = 1
      validate_lap(split_times, split, expected)
    end

    it 'returns 1 when split_times are present but not complete on lap 1 for the specified split' do
      split_times = test_split_times.first(4) # Start, Aid 1 (in/out), and Aid 2 (in)
      split = test_splits.third # Aid 2
      expected = 1
      validate_lap(split_times, split, expected)
    end

    it 'returns 2 when split_times are present and complete on lap 1 for the specified split' do
      split_times = test_split_times.first(5) # Start, Aid 1 (in/out), and Aid 2 (in/out)
      split = test_splits.third # Aid 2
      expected = 2
      validate_lap(split_times, split, expected)
    end

    it 'returns 3 when split_times are present and complete on lap 2 for the specified start split' do
      split_times = test_split_times.first(12) # Two full laps
      split = test_splits.first # Start
      expected = 3
      validate_lap(split_times, split, expected)
    end

    it 'returns 3 when split_times are present and complete on lap 2 for the specified intermediate split' do
      split_times = test_split_times.first(12) # Two full laps
      split = test_splits.second # Aid 1
      expected = 3
      validate_lap(split_times, split, expected)
    end

    it 'returns 3 when split_times are present and complete on lap 2 for the specified finish split' do
      split_times = test_split_times.first(12) # Two full laps
      split = test_splits.last # Finish
      expected = 3
      validate_lap(split_times, split, expected)
    end

    it 'returns 2 when a split_time is missing on lap 2 for the specified start split although split_times exist later on the lap' do
      split_times = test_split_times[0..5] + test_split_times[7..11] # Two full laps less the start on lap 2
      split = test_splits.first # Start
      expected = 2
      validate_lap(split_times, split, expected)
    end

    it 'returns 2 when a split_time is missing on lap 2 for the specified intermediate split although split_times exist later on the lap' do
      split_times = test_split_times[0..6] + test_split_times[8..11] # Two full laps less the Aid 1 In time on lap 2
      split = test_splits.second # Aid 1
      expected = 2
      validate_lap(split_times, split, expected)
    end

    it 'returns 3 although a split_time is missing on lap 1 for the specified intermediate split if the lap 2 split is complete' do
      split_times = test_split_times[0..2] + test_split_times[5..11] # Two full laps less the Aid 1 in/out times on lap 1
      split = test_splits.second # Aid 1
      expected = 3
      validate_lap(split_times, split, expected)
    end
  end

  def validate_lap(split_times, split, expected)
    finder = ExpectedLapFinder.new(ordered_split_times: split_times, split: split)
    expect(finder.lap).to eq(expected)
  end
end
