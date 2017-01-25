require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe IntendedTimeCalculator do
  let(:start_time) { Time.new(2016, 7, 1, 6, 0, 0) }
  let(:effort) { FactoryGirl.build_stubbed(:effort, start_time: start_time, id: 101) }

  describe '#initialize' do
    it 'initializes with a military time, an effort, and a sub_split in an args hash' do
      military_time = '15:30:45'
      effort = FactoryGirl.build_stubbed(:effort)
      time_point = TimePoint.new(1, 45, 1)
      expect { IntendedTimeCalculator.new(effort: effort,
                                          military_time: military_time,
                                          time_point: time_point,
                                          prior_valid_split_time: 123,
                                          expected_time_from_prior: 456) }.not_to raise_error
    end

    it 'raises an ArgumentError if no military time is given' do
      effort = FactoryGirl.build_stubbed(:effort)
      time_point = TimePoint.new(1, 45, 1)
      expect { IntendedTimeCalculator.new(effort: effort, time_point: time_point) }
          .to raise_error(/must include military_time/)
    end

    it 'raises an ArgumentError if no effort is given' do
      military_time = '15:30:45'
      time_point = TimePoint.new(1, 45, 1)
      expect { IntendedTimeCalculator.new(military_time: military_time, time_point: time_point) }
          .to raise_error(/must include effort/)
    end

    it 'raises an ArgumentError if no sub_split is given' do
      military_time = '15:30:45'
      effort = FactoryGirl.build_stubbed(:effort)
      expect { IntendedTimeCalculator.new(military_time: military_time, effort: effort) }
          .to raise_error(/must include time_point/)
    end
  end

  describe '#day_and_time' do
    before do
      FactoryGirl.reload
    end

    it 'returns nil if military_time provided is blank' do
      military_time = ''
      time_point = TimePoint.new(1, 44, 1)
      expected_time_from_prior = 10000
      prior_valid_split_time = FactoryGirl.build_stubbed(:split_times_in_only, time_point: time_point, time_from_start: 0)
      expected = nil
      validate_day_and_time(military_time, time_point, expected_time_from_prior, prior_valid_split_time, expected)
    end

    context 'for an effort that has not yet started' do
      it 'calculates the likely intended day and time for a same-day time based on inputs' do
        military_time = '9:30:45'
        time_point = TimePoint.new(1, 44, 1)
        expected_time_from_prior = 10000
        prior_valid_split_time = FactoryGirl.build_stubbed(:split_times_in_only, time_point: time_point, time_from_start: 0)
        expected = Time.new(2016, 7, 1, 9, 30, 45)
        validate_day_and_time(military_time, time_point, expected_time_from_prior, prior_valid_split_time, expected)
      end

      it 'calculates the likely intended day and time for a multi-day time based on inputs' do
        military_time = '15:30:45'
        time_point = TimePoint.new(1, 44, 1)
        expected_time_from_prior = 200000
        prior_valid_split_time = FactoryGirl.build_stubbed(:split_times_in_only, time_point: time_point, time_from_start: 0)
        expected = Time.new(2016, 7, 3, 15, 30, 45)
        validate_day_and_time(military_time, time_point, expected_time_from_prior, prior_valid_split_time, expected)
      end

      it 'calculates the likely intended day and time for a many-day time based on inputs' do
        military_time = '15:30:45'
        time_point = TimePoint.new(1, 44, 1)
        expected_time_from_prior = 400000
        prior_valid_split_time = FactoryGirl.build_stubbed(:split_times_in_only, time_point: time_point, time_from_start: 0)
        expected = Time.new(2016, 7, 5, 15, 30, 45)
        validate_day_and_time(military_time, time_point, expected_time_from_prior, prior_valid_split_time, expected)
      end

      it 'may be called using convenience class method IntendedTimeCalculator.day_and_time' do
        military_time = '15:30:45'
        time_point = TimePoint.new(1, 44, 1)
        expected_time_from_prior = 400000
        prior_valid_split_time = FactoryGirl.build_stubbed(:split_times_in_only, split_id: 44, bitkey: 1, time_from_start: 0)

        day_and_time = IntendedTimeCalculator.day_and_time(effort: effort,
                                                           military_time: military_time,
                                                           time_point: time_point,
                                                           expected_time_from_prior: expected_time_from_prior,
                                                           prior_valid_split_time: prior_valid_split_time)
        expect(day_and_time).to eq(Time.new(2016, 7, 5, 15, 30, 45))
      end
    end

    context 'for an effort partially underway' do
      let(:split_times) { FactoryGirl.build_stubbed_list(:split_times_hardrock_43, 30, effort_id: 101) }
      let(:time_points) { split_times.map(&:time_point) }
      let(:splits) { FactoryGirl.build_stubbed_list(:splits_hardrock_ccw, 16, course_id: 10) }

      it 'calculates the likely intended day and time based on inputs' do
        military_time = '18:00:00'
        time_point = time_points[9] # Burrows In
        expected_time_from_prior = 1.hour
        prior_valid_split_time = split_times[8]
        expected = Time.new(2016, 7, 1, 18, 0, 0)
        validate_day_and_time(military_time, time_point, expected_time_from_prior, prior_valid_split_time, expected)
      end

      it 'calculates the likely intended day and time based on inputs, where time is late evening' do
        military_time = '20:30:00'
        time_point = time_points[9] # Burrows In
        expected_time_from_prior = 1.hour
        prior_valid_split_time = split_times[8]
        expected = Time.new(2016, 7, 1, 20, 30, 0)
        validate_day_and_time(military_time, time_point, expected_time_from_prior, prior_valid_split_time, expected)
      end


      it 'rolls into the next day if necessary' do
        military_time = '1:00:00'
        time_point = time_points[9] # Burrows In
        expected_time_from_prior = 1.hour
        prior_valid_split_time = split_times[8]
        expected = Time.new(2016, 7, 2, 1, 0, 0)
        validate_day_and_time(military_time, time_point, expected_time_from_prior, prior_valid_split_time, expected)
      end

      it 'functions properly when intended time is well into the following day' do
        military_time = '5:30:00'
        time_point = time_points[9] # Burrows In
        expected_time_from_prior = 1.hour
        prior_valid_split_time = split_times[8]
        expected = Time.new(2016, 7, 2, 5, 30, 0)
        validate_day_and_time(military_time, time_point, expected_time_from_prior, prior_valid_split_time, expected)
      end

      it 'functions properly when expected time is near midnight' do
        military_time = '23:30:00'
        time_point = time_points[13] # Engineer In
        expected_time_from_prior = 8.hours
        prior_valid_split_time = split_times[8]
        expected = Time.new(2016, 7, 1, 23, 30, 0)
        validate_day_and_time(military_time, time_point, expected_time_from_prior, prior_valid_split_time, expected)
      end

      it 'functions properly when expected time is past midnight' do
        military_time = '00:30:00'
        time_point = time_points[13] # Engineer In
        expected_time_from_prior = 8.hours
        prior_valid_split_time = split_times[8]
        expected = Time.new(2016, 7, 2, 0, 30, 0)
        validate_day_and_time(military_time, time_point, expected_time_from_prior, prior_valid_split_time, expected)
      end

      it 'functions properly when expected time is early morning' do
        military_time = '5:30:00'
        time_point = time_points[13] # Engineer In
        expected_time_from_prior = 8.hours
        prior_valid_split_time = split_times[8]
        expected = Time.new(2016, 7, 2, 5, 30, 0)
        validate_day_and_time(military_time, time_point, expected_time_from_prior, prior_valid_split_time, expected)
      end

      it 'functions properly when expected time is mid morning' do
        military_time = '9:30:00'
        time_point = time_points[13] # Engineer In
        expected_time_from_prior = 8.hours
        prior_valid_split_time = split_times[8]
        expected = Time.new(2016, 7, 2, 9, 30, 0)
        validate_day_and_time(military_time, time_point, expected_time_from_prior, prior_valid_split_time, expected)
      end

      it 'rolls over to the next day if the calculated time is earlier than the effort start time' do
        military_time = '04:00:00' # Expected time is roughly 08:30 on 7/1, so this would normally be interpreted as 04:00 on 7/1
        time_point = time_points[1] # Cunningham In
        expected_time_from_prior = 150.minutes
        prior_valid_split_time = split_times[0]
        expected = Time.new(2016, 7, 2, 4, 0, 0)
        validate_day_and_time(military_time, time_point, expected_time_from_prior, prior_valid_split_time, expected)
      end
    end

    it 'raises a RangeError if military time is greater than 24 hours' do
      military_time = '25:30:45'
      effort = FactoryGirl.build_stubbed(:effort, start_time: start_time)
      time_point = TimePoint.new(1, 45, 1)
      expected_time_from_prior = 90.minutes
      prior_valid_split_time = SplitTime.new

      expect { IntendedTimeCalculator.new(effort: effort,
                                          military_time: military_time,
                                          time_point: time_point,
                                          expected_time_from_prior: expected_time_from_prior,
                                          prior_valid_split_time: prior_valid_split_time) }
          .to raise_error(/out of range/)
    end
  end

  def validate_day_and_time(military_time, time_point, expected_from_prior, prior_valid, expected)
    calculator = IntendedTimeCalculator.new(effort: effort,
                                            military_time: military_time,
                                            time_point: time_point,
                                            expected_time_from_prior: expected_from_prior,
                                            prior_valid_split_time: prior_valid)
    expect(calculator.day_and_time).to eq(expected)
  end
end