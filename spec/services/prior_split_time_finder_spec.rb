require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe PriorSplitTimeFinder do
  let(:test_event) { FactoryGirl.build_stubbed(:event_functional, laps_required: 3, splits_count: 3, efforts_count: 1) }
  let(:test_effort) { test_event.efforts.first }
  let(:test_split_times) { test_effort.split_times }

  let(:split_times_101) { FactoryGirl.build_stubbed_list(:split_times_in_out, 20,
                                                         effort_id: 101,
                                                         data_status: SplitTime::data_statuses[:good]).first(10) }
  let(:split_ids) { split_times_101.map(&:split_id).uniq }
  let(:split1) { FactoryGirl.build_stubbed(:start_split, id: split_ids[0], course_id: 10, distance_from_start: 0) }
  let(:split2) { FactoryGirl.build_stubbed(:split, id: split_ids[1], course_id: 10, distance_from_start: 1000) }
  let(:split3) { FactoryGirl.build_stubbed(:split, id: split_ids[2], course_id: 10, distance_from_start: 2000) }
  let(:split4) { FactoryGirl.build_stubbed(:split, id: split_ids[3], course_id: 10, distance_from_start: 3000) }
  let(:split5) { FactoryGirl.build_stubbed(:split, id: split_ids[4], course_id: 10, distance_from_start: 4000) }
  let(:split6) { FactoryGirl.build_stubbed(:finish_split, id: split_ids[5], course_id: 10, distance_from_start: 5000) }

  describe '#initialize' do
    it 'initializes with an effort, a time_point, lap_splits, and split_times in an args hash' do
      lap_splits, time_points = lap_splits_and_time_points(test_event)
      time_point = time_points.last
      split_times = test_split_times
      expect { PriorSplitTimeFinder.new(effort: test_effort,
                                        time_point: time_point,
                                        lap_splits: lap_splits,
                                        split_times: split_times) }.not_to raise_error
    end

    it 'raises an ArgumentError if neither effort nor lap_splits is given' do
      _, time_points = lap_splits_and_time_points(test_event)
      time_point = time_points.last
      expect { PriorSplitTimeFinder.new(time_point: time_point) }.to raise_error(/must include one of effort or lap_splits/)
    end

    it 'raises an ArgumentError if no time_point is given' do
      expect { PriorSplitTimeFinder.new(effort: test_effort) }.to raise_error(/must include time_point/)
    end
  end

  describe '#split_time' do
    before do
      FactoryGirl.reload
    end

    it 'when all split_times are valid, returns the split_time that comes immediately prior to the provided time_point' do
      lap_splits, time_points = lap_splits_and_time_points(test_event)
      time_point = time_points[5]
      split_times = test_split_times
      finder = PriorSplitTimeFinder.new(effort: test_effort,
                                        time_point: time_point,
                                        lap_splits: lap_splits,
                                        split_times: split_times)
      expected = split_times[4]
      expect(finder.split_time).to eq(expected)
    end

    it 'when some split_times are invalid, returns the latest valid split_time that comes prior to the provided time_point' do
      lap_splits, time_points = lap_splits_and_time_points(test_event)
      time_point = time_points[5]
      split_times = test_split_times
      split_times[5].data_status = 'bad'
      split_times[4].data_status = 'questionable'
      split_times[3].data_status = 'bad'
      finder = PriorSplitTimeFinder.new(effort: test_effort,
                                        time_point: time_point,
                                        lap_splits: lap_splits,
                                        split_times: split_times)
      expected = split_times[2]
      expect(finder.split_time).to eq(expected)
    end

    it 'when all prior split_times are invalid, returns nil' do
      lap_splits, time_points = lap_splits_and_time_points(test_event)
      time_point = time_points[4]
      split_times = test_split_times
      split_times[4].data_status = 'bad'
      split_times[3].data_status = 'questionable'
      split_times[2].data_status = 'bad'
      split_times[1].data_status = 'questionable'
      split_times[0].data_status = 'bad'
      finder = PriorSplitTimeFinder.new(effort: test_effort,
                                        time_point: time_point,
                                        lap_splits: lap_splits,
                                        split_times: split_times)
      expected = nil
      expect(finder.split_time).to eq(expected)
    end

    it 'when the starting time_point is provided, returns nil' do
      lap_splits, time_points = lap_splits_and_time_points(test_event)
      time_point = time_points[0]
      split_times = test_split_times
      finder = PriorSplitTimeFinder.new(effort: test_effort,
                                        time_point: time_point,
                                        lap_splits: lap_splits,
                                        split_times: split_times)
      expected = nil
      expect(finder.split_time).to eq(expected)
    end
  end

  describe '#guaranteed_split_time' do
    before do
      FactoryGirl.reload
    end

    it 'when split_time exists, returns split_time' do
      lap_splits, time_points = lap_splits_and_time_points(test_event)
      time_point = time_points[5]
      split_times = test_split_times
      finder = PriorSplitTimeFinder.new(effort: test_effort,
                                        time_point: time_point,
                                        lap_splits: lap_splits,
                                        split_times: split_times)
      expected = split_times[4]
      expect(finder.guaranteed_split_time).to eq(expected)
    end

    it 'when all prior split_times are invalid, returns a null record split_time' do
      lap_splits, time_points = lap_splits_and_time_points(test_event)
      time_point = time_points[4]
      split_times = test_split_times
      split_times[4].data_status = 'bad'
      split_times[3].data_status = 'questionable'
      split_times[2].data_status = 'bad'
      split_times[1].data_status = 'questionable'
      split_times[0].data_status = 'bad'
      finder = PriorSplitTimeFinder.new(effort: test_effort,
                                        time_point: time_point,
                                        lap_splits: lap_splits,
                                        split_times: split_times)
      expected = SplitTime.new(time_point: time_points.first, time_from_start: 0, id: nil, effort_id: nil)
      expect(finder.guaranteed_split_time.attributes).to eq(expected.attributes)
    end

    it 'when all the starting time_point is provided, returns a null record split_time' do
      lap_splits, time_points = lap_splits_and_time_points(test_event)
      time_point = time_points[0]
      split_times = test_split_times
      finder = PriorSplitTimeFinder.new(effort: test_effort,
                                        time_point: time_point,
                                        lap_splits: lap_splits,
                                        split_times: split_times)
      expected = SplitTime.new(time_point: time_points.first, time_from_start: 0, id: nil, effort_id: nil)
      expect(finder.guaranteed_split_time.attributes).to eq(expected.attributes)
    end
  end

  def lap_splits_and_time_points(event)
    allow(event).to receive(:ordered_splits).and_return(event.splits)
    lap_splits = event.required_lap_splits
    time_points = lap_splits.map(&:time_points).flatten
    [lap_splits, time_points]
  end
end