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
                                          sub_split: sub_split) }.not_to raise_error
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

      calculator = IntendedTimeCalculator.new(effort: effort,
                                              military_time: military_time,
                                              sub_split: sub_split,
                                              predictor: time_predictor)
      expect(calculator.day_and_time).to eq(Time.new(2016, 7, 1, 9, 30, 45))

      day_and_time = IntendedTimeCalculator.day_and_time(effort: effort,
                                                         military_time: military_time,
                                                         sub_split: sub_split,
                                                         predictor: time_predictor)
      expect(day_and_time).to eq(Time.new(2016, 7, 1, 9, 30, 45))
    end

    it 'calculates the likely intended day and time for a multi-day time based on inputs' do
      military_time = '15:30:45'
      start_time = Time.new(2016, 7, 1, 6, 0, 0)
      effort = FactoryGirl.build_stubbed(:effort, start_time: start_time)
      sub_split = {45 => 1}
      mock_time_hash = {{44 => 1} => 10000, {45 => 1} => 200000, {46 => 1} => 400000}
      time_predictor = instance_double('TimesPredictor', times_from_start: mock_time_hash)

      calculator = IntendedTimeCalculator.new(effort: effort,
                                              military_time: military_time,
                                              sub_split: sub_split,
                                              predictor: time_predictor)
      expect(calculator.day_and_time).to eq(Time.new(2016, 7, 3, 15, 30, 45))

      day_and_time = IntendedTimeCalculator.day_and_time(effort: effort,
                                                         military_time: military_time,
                                                         sub_split: sub_split,
                                                         predictor: time_predictor)
      expect(day_and_time).to eq(Time.new(2016, 7, 3, 15, 30, 45))
    end

    it 'calculates the likely intended day and time for a many-day time based on inputs' do
      military_time = '15:30:45'
      start_time = Time.new(2016, 7, 1, 6, 0, 0)
      effort = FactoryGirl.build_stubbed(:effort, start_time: start_time)
      sub_split = {46 => 1}
      mock_time_hash = {{44 => 1} => 10000, {45 => 1} => 200000, {46 => 1} => 400000}
      time_predictor = instance_double('TimesPredictor', times_from_start: mock_time_hash)

      calculator = IntendedTimeCalculator.new(effort: effort,
                                              military_time: military_time,
                                              sub_split: sub_split,
                                              predictor: time_predictor)
      expect(calculator.day_and_time).to eq(Time.new(2016, 7, 5, 15, 30, 45))

      day_and_time = IntendedTimeCalculator.day_and_time(effort: effort,
                                                         military_time: military_time,
                                                         sub_split: sub_split,
                                                         predictor: time_predictor)
      expect(day_and_time).to eq(Time.new(2016, 7, 5, 15, 30, 45))
    end

    context 'for an effort partially underway' do
      let(:split_times) { FactoryGirl.build_stubbed_list(:split_times_in_out, 20, effort_id: 101).first(10) }
      let(:split_ids) { split_times_101.map(&:split_id).uniq }
      let(:split1) { FactoryGirl.build_stubbed(:start_split, id: split_ids[0], course_id: 10, distance_from_start: 0) }
      let(:split2) { FactoryGirl.build_stubbed(:split, id: split_ids[1], course_id: 10, distance_from_start: 14966) }
      let(:split3) { FactoryGirl.build_stubbed(:split, id: split_ids[2], course_id: 10, distance_from_start: 24783) }
      let(:split4) { FactoryGirl.build_stubbed(:split, id: split_ids[3], course_id: 10, distance_from_start: 31704) }
      let(:split5) { FactoryGirl.build_stubbed(:split, id: split_ids[4], course_id: 10, distance_from_start: 46349) }
      let(:split6) { FactoryGirl.build_stubbed(:finish_split, id: split_ids[5], course_id: 10, distance_from_start: 52464) }

      it 'calculates the likely intended day and time for a same-day time based on inputs' do
        split_times[1].time_from_start = 11160
        split_times[2].time_from_start = 11160
        split_times[3].time_from_start = 20880
        split_times[4].time_from_start = 21060
        split_times[5].time_from_start = 25680
        split_times[6].time_from_start = 25740
        split_times[7].time_from_start = 35820
        split_times[8].time_from_start = 36480
        split_times[9].time_from_start = 40740
        puts split_times.map { |st| "#{st.id}, #{st.split_id}, #{st.bitkey}, #{st.time_from_start}" }
        military_time = '8:00:00'
        start_time = Time.new(2016, 7, 1, 6, 0, 0)
        effort = FactoryGirl.build_stubbed(:effort, start_time: start_time, id: 101)

        ordered_splits = [split1, split2, split3, split4, split5, split6]
        valid_split_times = split_times
        time_predictor = TimesPredictor.new(effort: effort,
                                       ordered_splits: ordered_splits,
                                       valid_split_times: valid_split_times,
                                       calculate_by: :terrain)

        sub_split = split_times.last.sub_split

        expected = Time.new(2016, 7, 2, 8, 0, 0)

        calculator = IntendedTimeCalculator.new(effort: effort,
                                                military_time: military_time,
                                                sub_split: sub_split,
                                                predictor: time_predictor)
        expect(calculator.day_and_time).to eq(expected)

        day_and_time = IntendedTimeCalculator.day_and_time(effort: effort,
                                                           military_time: military_time,
                                                           sub_split: sub_split,
                                                           predictor: time_predictor)
        expect(day_and_time).to eq(expected)
      end
    end


    it 'raises a RangeError if military time is greater than 24 hours' do
      military_time = '25:30:45'
      start_time = Time.new(2016, 7, 1, 6, 0, 0)
      effort = FactoryGirl.build_stubbed(:effort, start_time: start_time)
      sub_split = {46 => 1}
      mock_time_hash = {{44 => 1} => 10000, {45 => 1} => 200000, {46 => 1} => 400000}
      time_predictor = instance_double('TimesPredictor', times_from_start: mock_time_hash)

      expect { IntendedTimeCalculator.new(effort: effort,
                                          military_time: military_time,
                                          sub_split: sub_split,
                                          predictor: time_predictor) }.to raise_error(/out of range/)
    end
  end
end