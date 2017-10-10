require 'rails_helper'

RSpec.describe SplitTimeFinder do
  let(:test_event) { build_stubbed(:event_functional, laps_required: 3, splits_count: 3, efforts_count: 1) }
  let(:test_effort) { test_event.efforts.first }
  let(:test_split_times) { test_effort.split_times }

  describe '#initialize' do
    it 'initializes with an effort, a time_point, lap_splits, and split_times in an args hash' do
      lap_splits, time_points = lap_splits_and_time_points(test_event)
      time_point = time_points.last
      split_times = test_split_times
      expect { SplitTimeFinder.new(effort: test_effort,
                                   time_point: time_point,
                                   lap_splits: lap_splits,
                                   split_times: split_times) }.not_to raise_error
    end

    it 'raises an ArgumentError if neither effort nor lap_splits is given' do
      _, time_points = lap_splits_and_time_points(test_event)
      time_point = time_points.last
      expect { SplitTimeFinder.new(time_point: time_point) }.to raise_error(/must include one of effort or lap_splits/)
    end

    it 'raises an ArgumentError if no time_point is given' do
      expect { SplitTimeFinder.new(effort: test_effort) }.to raise_error(/must include time_point/)
    end
  end

  describe '#prior' do
    before do
      FactoryGirl.reload
    end
    context 'if args[:valid] is not provided' do
      it 'when all split_times are valid, returns the split_time that comes immediately prior to the provided time_point' do
        lap_splits, time_points = lap_splits_and_time_points(test_event)
        time_point = time_points[5]
        split_times = test_split_times
        expected = split_times[4]
        validate_prior(time_point, lap_splits, split_times, expected)
      end

      it 'when some split_times are invalid, returns the latest valid split_time that comes prior to the provided time_point' do
        lap_splits, time_points = lap_splits_and_time_points(test_event)
        time_point = time_points[5]
        split_times = test_split_times
        split_times[4].data_status = 'questionable'
        split_times[3].data_status = 'bad'
        expected = split_times[2]
        validate_prior(time_point, lap_splits, split_times, expected)
      end

      it 'when all prior split_times are invalid, returns nil' do
        lap_splits, time_points = lap_splits_and_time_points(test_event)
        time_point = time_points[4]
        split_times = test_split_times
        split_times[3].data_status = 'questionable'
        split_times[2].data_status = 'bad'
        split_times[1].data_status = 'questionable'
        split_times[0].data_status = 'bad'
        expected = nil
        validate_prior(time_point, lap_splits, split_times, expected)
      end

      it 'when the starting time_point is provided, returns nil' do
        lap_splits, time_points = lap_splits_and_time_points(test_event)
        time_point = time_points[0]
        split_times = test_split_times
        expected = nil
        validate_prior(time_point, lap_splits, split_times, expected)
      end
    end

    context 'if args[:valid] is false' do
      it 'when all split_times are valid, returns the split_time that comes immediately prior to the provided time_point' do
        lap_splits, time_points = lap_splits_and_time_points(test_event)
        time_point = time_points[5]
        split_times = test_split_times
        valid = false
        expected = split_times[4]
        validate_prior(time_point, lap_splits, split_times, expected, valid)
      end

      it 'when some split_times are invalid, returns the latest valid split_time that comes prior to the provided time_point' do
        lap_splits, time_points = lap_splits_and_time_points(test_event)
        time_point = time_points[5]
        split_times = test_split_times
        split_times[4].data_status = 'questionable'
        split_times[3].data_status = 'bad'
        valid = false
        expected = split_times[4]
        validate_prior(time_point, lap_splits, split_times, expected, valid)
      end
    end

    def validate_prior(time_point, lap_splits, split_times, expected, valid = true)
      finder = SplitTimeFinder.new(effort: test_effort,
                                   time_point: time_point,
                                   lap_splits: lap_splits,
                                   split_times: split_times,
                                   valid: valid)
      expect(finder.prior).to eq(expected)
    end
  end

  describe '#next' do
    before do
      FactoryGirl.reload
    end

    it 'when all split_times are valid, returns the split_time that comes immediately after the provided time_point' do
      lap_splits, time_points = lap_splits_and_time_points(test_event)
      time_point = time_points[5]
      split_times = test_split_times
      expected = split_times[6]
      validate_next(time_point, lap_splits, split_times, expected)
    end

    it 'when some split_times are invalid, returns the first valid split_time that comes after the provided time_point' do
      lap_splits, time_points = lap_splits_and_time_points(test_event)
      time_point = time_points[2]
      split_times = test_split_times
      split_times[5].data_status = 'bad'
      split_times[4].data_status = 'questionable'
      split_times[3].data_status = 'bad'
      expected = split_times[6]
      validate_next(time_point, lap_splits, split_times, expected)
    end

    it 'when all later split_times are invalid, returns nil' do
      lap_splits, time_points = lap_splits_and_time_points(test_event)
      time_point = time_points[-5]
      split_times = test_split_times
      split_times[-4].data_status = 'bad'
      split_times[-3].data_status = 'questionable'
      split_times[-2].data_status = 'bad'
      split_times[-1].data_status = 'questionable'
      expected = nil
      validate_next(time_point, lap_splits, split_times, expected)
    end

    it 'when the last time_point is provided, returns nil' do
      lap_splits, time_points = lap_splits_and_time_points(test_event)
      time_point = time_points[-1]
      split_times = test_split_times
      expected = nil
      validate_next(time_point, lap_splits, split_times, expected)
    end

    def validate_next(time_point, lap_splits, split_times, expected)
      finder = SplitTimeFinder.new(effort: test_effort,
                                   time_point: time_point,
                                   lap_splits: lap_splits,
                                   split_times: split_times)
      expect(finder.next).to eq(expected)
    end
  end

  describe '#guaranteed_prior' do
    before do
      FactoryGirl.reload
    end

    it 'when split_time exists, returns split_time' do
      lap_splits, time_points = lap_splits_and_time_points(test_event)
      time_point = time_points[5]
      split_times = test_split_times
      expected = split_times[4]
      validate_guaranteed_prior(time_point, lap_splits, split_times, expected)
    end

    it 'when all prior split_times are invalid, returns a mock start split_time associated with the provided effort' do
      lap_splits, time_points = lap_splits_and_time_points(test_event)
      time_point = time_points[4]
      split_times = test_split_times
      split_times[4].data_status = 'bad'
      split_times[3].data_status = 'questionable'
      split_times[2].data_status = 'bad'
      split_times[1].data_status = 'questionable'
      split_times[0].data_status = 'bad'
      expected = SplitTime.new(time_point: time_points.first, time_from_start: 0, id: nil, effort: test_effort)
      validate_guaranteed_prior(time_point, lap_splits, split_times, expected)
    end

    it 'when all the starting time_point is provided, returns a null record split_time' do
      lap_splits, time_points = lap_splits_and_time_points(test_event)
      time_point = time_points[0]
      split_times = test_split_times
      expected = SplitTime.new(time_point: time_points.first, time_from_start: 0, id: nil, effort_id: test_effort.id)
      validate_guaranteed_prior(time_point, lap_splits, split_times, expected)
    end

    def validate_guaranteed_prior(time_point, lap_splits, split_times, expected)
      finder = SplitTimeFinder.new(effort: test_effort,
                                   time_point: time_point,
                                   lap_splits: lap_splits,
                                   split_times: split_times)
      expect(finder.guaranteed_prior.attributes).to eq(expected.attributes)
    end
  end
end
