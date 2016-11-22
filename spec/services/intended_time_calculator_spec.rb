require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe IntendedTimeCalculator do
  let(:split_times_101) { FactoryGirl.build_stubbed_list(:split_times_in_out, 20, effort_id: 101).first(10) }
  let(:split_ids) { split_times_101.map(&:split_id).uniq }
  let(:split1) { FactoryGirl.build_stubbed(:start_split, id: split_ids[0], course_id: 10, distance_from_start: 0) }
  let(:split2) { FactoryGirl.build_stubbed(:split, id: split_ids[1], course_id: 10, distance_from_start: 1000) }
  let(:split3) { FactoryGirl.build_stubbed(:split, id: split_ids[2], course_id: 10, distance_from_start: 2000) }
  let(:split4) { FactoryGirl.build_stubbed(:split, id: split_ids[3], course_id: 10, distance_from_start: 3000) }
  let(:split5) { FactoryGirl.build_stubbed(:split, id: split_ids[4], course_id: 10, distance_from_start: 4000) }
  let(:split6) { FactoryGirl.build_stubbed(:finish_split, id: split_ids[5], course_id: 10, distance_from_start: 5000) }

  describe '#initialize' do
    it 'initializes with a military time, an effort, and a sub_split in an args hash' do
      military_time = '15:30:45'
      effort = FactoryGirl.build_stubbed(:effort)
      sub_split = {45 => 1}
      expect { IntendedTimeCalculator.new(effort: effort,
                                          military_time: military_time,
                                          sub_split: sub_split,
                                          split_time_finder: 123) }.not_to raise_error
    end

    it 'raises an ArgumentError if no military time is given' do
      effort = FactoryGirl.build_stubbed(:effort)
      sub_split = {45 => 1}
      expect { IntendedTimeCalculator.new(effort: effort, sub_split: sub_split) }
          .to raise_error(/must include military_time/)
    end

    it 'raises an ArgumentError if no effort is given' do
      military_time = '15:30:45'
      sub_split = {45 => 1}
      expect { IntendedTimeCalculator.new(military_time: military_time, sub_split: sub_split) }
          .to raise_error(/must include effort/)
    end

    it 'raises an ArgumentError if no sub_split is given' do
      military_time = '15:30:45'
      effort = FactoryGirl.build_stubbed(:effort)
      expect { IntendedTimeCalculator.new(military_time: military_time, effort: effort) }
          .to raise_error(/must include sub_split/)
    end
  end

  describe '.day_and_time / #day_and_time' do
    context 'for an effort that has not yet started'
    it 'calculates the likely intended day and time for a same-day time based on inputs' do
      military_time = '9:30:45'
      start_time = Time.new(2016, 7, 1, 6, 0, 0)
      effort = FactoryGirl.build_stubbed(:effort, start_time: start_time)
      sub_split = {44 => 1}
      mock_time_hash = {{44 => 1} => 10000, {45 => 1} => 200000, {46 => 1} => 400000}
      time_predictor = instance_double('TimesPredictor', times_from_start: mock_time_hash)

      prior_split_time = FactoryGirl.build_stubbed(:split_times_in_only, split_id: 44, bitkey: 1, time_from_start: 0)
      split_time_finder = instance_double('PriorSplitTimeFinder', split_time: prior_split_time)

      calculator = IntendedTimeCalculator.new(effort: effort,
                                              military_time: military_time,
                                              sub_split: sub_split,
                                              predictor: time_predictor,
                                              split_time_finder: split_time_finder)
      expect(calculator.day_and_time).to eq(Time.new(2016, 7, 1, 9, 30, 45))

      day_and_time = IntendedTimeCalculator.day_and_time(effort: effort,
                                                         military_time: military_time,
                                                         sub_split: sub_split,
                                                         predictor: time_predictor,
                                                         split_time_finder: split_time_finder)
      expect(day_and_time).to eq(Time.new(2016, 7, 1, 9, 30, 45))
    end

    it 'calculates the likely intended day and time for a multi-day time based on inputs' do
      military_time = '15:30:45'
      start_time = Time.new(2016, 7, 1, 6, 0, 0)
      effort = FactoryGirl.build_stubbed(:effort, start_time: start_time)
      sub_split = {45 => 1}
      mock_time_hash = {{44 => 1} => 10000, {45 => 1} => 200000, {46 => 1} => 400000}
      time_predictor = instance_double('TimesPredictor', times_from_start: mock_time_hash)

      prior_split_time = FactoryGirl.build_stubbed(:split_times_in_only, split_id: 44, bitkey: 1, time_from_start: 0)
      split_time_finder = instance_double('PriorSplitTimeFinder', split_time: prior_split_time)

      calculator = IntendedTimeCalculator.new(effort: effort,
                                              military_time: military_time,
                                              sub_split: sub_split,
                                              predictor: time_predictor,
                                              split_time_finder: split_time_finder)
      expect(calculator.day_and_time).to eq(Time.new(2016, 7, 3, 15, 30, 45))

      day_and_time = IntendedTimeCalculator.day_and_time(effort: effort,
                                                         military_time: military_time,
                                                         sub_split: sub_split,
                                                         predictor: time_predictor,
                                                         split_time_finder: split_time_finder)
      expect(day_and_time).to eq(Time.new(2016, 7, 3, 15, 30, 45))
    end

    it 'calculates the likely intended day and time for a many-day time based on inputs' do
      military_time = '15:30:45'
      start_time = Time.new(2016, 7, 1, 6, 0, 0)
      effort = FactoryGirl.build_stubbed(:effort, start_time: start_time)
      sub_split = {46 => 1}

      mock_time_hash = {{44 => 1} => 10000, {45 => 1} => 200000, {46 => 1} => 400000}
      time_predictor = instance_double('TimesPredictor', times_from_start: mock_time_hash)

      prior_split_time = FactoryGirl.build_stubbed(:split_times_in_only, split_id: 44, bitkey: 1, time_from_start: 0)
      split_time_finder = instance_double('PriorSplitTimeFinder', split_time: prior_split_time)

      calculator = IntendedTimeCalculator.new(effort: effort,
                                              military_time: military_time,
                                              sub_split: sub_split,
                                              predictor: time_predictor,
                                              split_time_finder: split_time_finder)
      expect(calculator.day_and_time).to eq(Time.new(2016, 7, 5, 15, 30, 45))

      day_and_time = IntendedTimeCalculator.day_and_time(effort: effort,
                                                         military_time: military_time,
                                                         sub_split: sub_split,
                                                         predictor: time_predictor,
                                                         split_time_finder: split_time_finder)
      expect(day_and_time).to eq(Time.new(2016, 7, 5, 15, 30, 45))
    end

    context 'for an effort partially underway' do
      let(:split_times) { FactoryGirl.build_stubbed_list(:split_times_hardrock_1, 30, effort_id: 101) }
      let(:splits) { FactoryGirl.build_stubbed_list(:splits_hardrock_ccw, 16, course_id: 10) }

      it 'calculates the likely intended day and time based on inputs, rolling into the next day if necessary' do
        effort = FactoryGirl.build_stubbed(:effort, start_time: Time.new(2016, 7, 1, 6, 0, 0), id: 101)
        ordered_splits = splits
        valid_split_times = split_times
        time_predictor = TimesPredictor.new(effort: effort,
                                            ordered_splits: ordered_splits,
                                            valid_split_times: valid_split_times,
                                            calculate_by: :terrain)
        split_time_finder = instance_double('PriorSplitTimeFinder', split_time: split_times[8])

        sub_split = split_times[9].sub_split # Burrows In

        military_time = '18:00:00'
        calculator = IntendedTimeCalculator.new(effort: effort,
                                                military_time: military_time,
                                                sub_split: sub_split,
                                                predictor: time_predictor,
                                                split_time_finder: split_time_finder)
        expected = Time.new(2016, 7, 1, 18, 0, 0)
        expect(calculator.day_and_time).to eq(expected)

        military_time = '20:30:00'
        calculator = IntendedTimeCalculator.new(effort: effort,
                                                military_time: military_time,
                                                sub_split: sub_split,
                                                predictor: time_predictor,
                                                split_time_finder: split_time_finder)
        expected = Time.new(2016, 7, 1, 20, 30, 0)
        expect(calculator.day_and_time).to eq(expected)

        military_time = '1:00:00'
        calculator = IntendedTimeCalculator.new(effort: effort,
                                                military_time: military_time,
                                                sub_split: sub_split,
                                                predictor: time_predictor,
                                                split_time_finder: split_time_finder)
        expected = Time.new(2016, 7, 2, 1, 0, 0)
        expect(calculator.day_and_time).to eq(expected)

        military_time = '5:30:00'
        calculator = IntendedTimeCalculator.new(effort: effort,
                                                military_time: military_time,
                                                sub_split: sub_split,
                                                predictor: time_predictor,
                                                split_time_finder: split_time_finder)
        expected = Time.new(2016, 7, 2, 5, 30, 0)
        expect(calculator.day_and_time).to eq(expected)
      end

      it 'functions properly when expected time is near midnight' do
        effort = FactoryGirl.build_stubbed(:effort, start_time: Time.new(2016, 7, 1, 6, 0, 0), id: 101)
        ordered_splits = splits
        valid_split_times = split_times
        time_predictor = TimesPredictor.new(effort: effort,
                                            ordered_splits: ordered_splits,
                                            valid_split_times: valid_split_times,
                                            calculate_by: :terrain)
        split_time_finder = instance_double('PriorSplitTimeFinder', split_time: split_times[8])

        sub_split = split_times[13].sub_split # Engineer In

        military_time = '23:30:00'
        calculator = IntendedTimeCalculator.new(effort: effort,
                                                military_time: military_time,
                                                sub_split: sub_split,
                                                predictor: time_predictor,
                                                split_time_finder: split_time_finder)
        expected = Time.new(2016, 7, 1, 23, 30, 0)
        expect(calculator.day_and_time).to eq(expected)

        military_time = '00:30:00'
        calculator = IntendedTimeCalculator.new(effort: effort,
                                                military_time: military_time,
                                                sub_split: sub_split,
                                                predictor: time_predictor,
                                                split_time_finder: split_time_finder)
        expected = Time.new(2016, 7, 2, 0, 30, 0)
        expect(calculator.day_and_time).to eq(expected)

        military_time = '5:30:00'
        calculator = IntendedTimeCalculator.new(effort: effort,
                                                military_time: military_time,
                                                sub_split: sub_split,
                                                predictor: time_predictor,
                                                split_time_finder: split_time_finder)
        expected = Time.new(2016, 7, 2, 5, 30, 0)
        expect(calculator.day_and_time).to eq(expected)

        military_time = '9:30:00'
        calculator = IntendedTimeCalculator.new(effort: effort,
                                                military_time: military_time,
                                                sub_split: sub_split,
                                                predictor: time_predictor,
                                                split_time_finder: split_time_finder)
        expected = Time.new(2016, 7, 2, 9, 30, 0)
        expect(calculator.day_and_time).to eq(expected)
      end

      it 'rolls over to the next day if prior valid split time is later than the calculated time' do
        effort = FactoryGirl.build_stubbed(:effort, start_time: Time.new(2016, 7, 1, 6, 0, 0), id: 101)
        ordered_splits = splits
        valid_split_times = split_times
        time_predictor = TimesPredictor.new(effort: effort,
                                            ordered_splits: ordered_splits,
                                            valid_split_times: valid_split_times,
                                            calculate_by: :terrain)
        split_time_finder = instance_double('PriorSplitTimeFinder', split_time: split_times[8])

        military_time = '16:00:00' # Expected time is roughly 17:00 on 7/1, so this would normally be interpreted as 16:00 on 7/1
        sub_split = split_times[9].sub_split
        calculator = IntendedTimeCalculator.new(effort: effort,
                                                military_time: military_time,
                                                sub_split: sub_split,
                                                predictor: time_predictor,
                                                split_time_finder: split_time_finder)
        expected = Time.new(2016, 7, 2, 16, 0, 0)
        expect(calculator.day_and_time).to eq(expected)
      end
    end

    it 'raises a RangeError if military time is greater than 24 hours' do
      military_time = '25:30:45'
      start_time = Time.new(2016, 7, 1, 6, 0, 0)
      effort = FactoryGirl.build_stubbed(:effort, start_time: start_time)
      sub_split = {46 => 1}
      mock_time_hash = {{44 => 1} => 10000, {45 => 1} => 200000, {46 => 1} => 400000}
      time_predictor = instance_double('TimesPredictor', times_from_start: mock_time_hash)
      split_time_finder = instance_double('PriorSplitTimeFinder', split_time: SplitTime.new)

      expect { IntendedTimeCalculator.new(effort: effort,
                                          military_time: military_time,
                                          sub_split: sub_split,
                                          predictor: time_predictor,
                                          split_time_finder: split_time_finder) }.to raise_error(/out of range/)
    end
  end
end