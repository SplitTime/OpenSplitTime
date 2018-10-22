# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IntendedTimeCalculator do
  subject { IntendedTimeCalculator.new(effort: effort,
                                       military_time: military_time,
                                       time_point: time_point,
                                       prior_valid_split_time: prior_valid_split_time,
                                       expected_time_from_prior: expected_time_from_prior) }
  let(:effort) { build_stubbed(:effort, event: event) }
  let(:event) { build_stubbed(:event, start_time_in_home_zone: '2016-07-01 06:00:00') }
  let(:home_time_zone) { event.home_time_zone }
  let(:military_time) { '15:30:45' }
  let(:time_point) { TimePoint.new(1, 45, 1) }
  let(:prior_valid_split_time) { build_stubbed(:split_time, time_point: time_point, absolute_time: event.start_time_in_home_zone) }
  let(:expected_time_from_prior) { 10_000 }

  describe '#initialize' do
    context 'when a military time, an effort, and a sub_split are provided' do
      it 'initializes with no errors' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when no military_time is provided' do
      let(:military_time) { nil }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(/must include military_time/)
      end
    end

    context 'when no effort is provided' do
      let(:effort) { nil }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(/must include effort/)
      end
    end

    context 'when no time_point is provided' do
      let(:time_point) { nil }
      let(:prior_valid_split_time) { SplitTime.new }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(/must include time_point/)
      end
    end
  end

  describe '#day_and_time' do
    context 'when military_time provided is blank' do
      let(:military_time) { '' }

      it 'returns nil' do
        expect(subject.day_and_time).to eq(nil)
      end
    end

    context 'when the effort has not yet started' do
      let(:military_time) { '9:30:45' }

      it 'calculates the likely intended day and time for a same-day time based on inputs' do
        expected = '2016-07-01 09:30:45'.in_time_zone(home_time_zone)
        expect(subject.day_and_time).to eq(expected)
      end

      it 'calculates the likely intended day and time for a multi-day time based on inputs' do
        military_time = '15:30:45'
        expected_time_from_prior = 200000
        expected = ActiveSupport::TimeZone[home_time_zone].parse('2016-07-03 15:30:45')
        validate_day_and_time(military_time, time_point, expected_time_from_prior, prior_valid_split_time, expected)
      end

      it 'calculates the likely intended day and time for a many-day time based on inputs' do
        military_time = '15:30:45'
        expected_time_from_prior = 400000
        expected = ActiveSupport::TimeZone[home_time_zone].parse('2016-07-05 15:30:45')
        validate_day_and_time(military_time, time_point, expected_time_from_prior, prior_valid_split_time, expected)
      end

      it 'may be called using convenience class method IntendedTimeCalculator.day_and_time' do
        military_time = '15:30:45'
        expected_time_from_prior = 400000
        expected = ActiveSupport::TimeZone[home_time_zone].parse('2016-07-05 15:30:45')

        day_and_time = IntendedTimeCalculator.day_and_time(effort: effort,
                                                           military_time: military_time,
                                                           time_point: time_point,
                                                           expected_time_from_prior: expected_time_from_prior,
                                                           prior_valid_split_time: prior_valid_split_time)
        expect(day_and_time).to eq(expected)
      end
    end

    context 'for an effort partially underway' do
      let(:split_times) { build_stubbed_list(:split_times_hardrock_43, 30, effort_id: 101) }
      let(:time_points) { split_times.map(&:time_point) }
      let(:splits) { build_stubbed_list(:splits_hardrock_ccw, 16, course_id: 10) }

      it 'calculates the likely intended day and time based on inputs' do
        military_time = '18:00:00'
        time_point = time_points[9] # Burrows In
        expected_time_from_prior = 1.hour
        prior_valid_split_time = split_times[8]
        expected = ActiveSupport::TimeZone[home_time_zone].parse('2016-07-01 18:00:00')
        validate_day_and_time(military_time, time_point, expected_time_from_prior, prior_valid_split_time, expected)
      end

      it 'calculates the likely intended day and time based on inputs, where time is late evening' do
        military_time = '20:30:00'
        time_point = time_points[9] # Burrows In
        expected_time_from_prior = 1.hour
        prior_valid_split_time = split_times[8]
        expected = ActiveSupport::TimeZone[home_time_zone].parse('2016-07-01 20:30:00')
        validate_day_and_time(military_time, time_point, expected_time_from_prior, prior_valid_split_time, expected)
      end

      it 'rolls into the next day if necessary' do
        military_time = '1:00:00'
        time_point = time_points[9] # Burrows In
        expected_time_from_prior = 1.hour
        prior_valid_split_time = split_times[8]
        expected = ActiveSupport::TimeZone[home_time_zone].parse('2016-07-02 01:00:00')
        validate_day_and_time(military_time, time_point, expected_time_from_prior, prior_valid_split_time, expected)
      end

      it 'functions properly when intended time is well into the following day' do
        military_time = '5:30:00'
        time_point = time_points[9] # Burrows In
        expected_time_from_prior = 1.hour
        prior_valid_split_time = split_times[8]
        expected = ActiveSupport::TimeZone[home_time_zone].parse('2016-07-02 05:30:00')
        validate_day_and_time(military_time, time_point, expected_time_from_prior, prior_valid_split_time, expected)
      end

      it 'functions properly when expected time is near midnight' do
        military_time = '23:30:00'
        time_point = time_points[13] # Engineer In
        expected_time_from_prior = 8.hours
        prior_valid_split_time = split_times[8]
        expected = ActiveSupport::TimeZone[home_time_zone].parse('2016-07-01 23:30:00')
        validate_day_and_time(military_time, time_point, expected_time_from_prior, prior_valid_split_time, expected)
      end

      it 'functions properly when expected time is past midnight' do
        military_time = '00:30:00'
        time_point = time_points[13] # Engineer In
        expected_time_from_prior = 8.hours
        prior_valid_split_time = split_times[8]
        expected = ActiveSupport::TimeZone[home_time_zone].parse('2016-07-02 00:30:00')
        validate_day_and_time(military_time, time_point, expected_time_from_prior, prior_valid_split_time, expected)
      end

      it 'functions properly when expected time is early morning' do
        military_time = '5:30:00'
        time_point = time_points[13] # Engineer In
        expected_time_from_prior = 8.hours
        prior_valid_split_time = split_times[8]
        expected = ActiveSupport::TimeZone[home_time_zone].parse('2016-07-02 05:30:00')
        validate_day_and_time(military_time, time_point, expected_time_from_prior, prior_valid_split_time, expected)
      end

      it 'functions properly when expected time is mid morning' do
        military_time = '9:30:00'
        time_point = time_points[13] # Engineer In
        expected_time_from_prior = 8.hours
        prior_valid_split_time = split_times[8]
        expected = ActiveSupport::TimeZone[home_time_zone].parse('2016-07-02 09:30:00')
        validate_day_and_time(military_time, time_point, expected_time_from_prior, prior_valid_split_time, expected)
      end

      it 'rolls over to the next day if the calculated time is more than three hours before the prior valid time' do
        military_time = '02:30:00' # Expected time is roughly 08:30 on 7/1, so this would normally be interpreted as 02:30 on 7/1
        time_point = time_points[1] # Cunningham In
        expected_time_from_prior = 150.minutes
        prior_valid_split_time = split_times[0]
        expected = ActiveSupport::TimeZone[home_time_zone].parse('2016-07-02 02:30:00')
        validate_day_and_time(military_time, time_point, expected_time_from_prior, prior_valid_split_time, expected)
      end
    end

    it 'raises a RangeError if military time is greater than 24 hours' do
      military_time = '25:30:45'
      effort = build_stubbed(:effort)
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
end
