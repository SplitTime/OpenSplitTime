# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IntendedTimeCalculator do
  subject { IntendedTimeCalculator.new(effort: effort,
                                       military_time: military_time,
                                       time_point: time_point,
                                       prior_valid_split_time: prior_valid_split_time,
                                       expected_time_from_prior: expected_time_from_prior) }
  let(:effort) { build_stubbed(:effort) }
  let(:time_point) { TimePoint.new(1, 45, 1) }
  let(:military_time) { '15:30:45' }
  let(:prior_valid_split_time) { SplitTime.new }
  let(:expected_time_from_prior) { 0 }

  describe '#initialize' do
    context 'with a military time, an effort, and a sub_split in an args hash' do
      it 'initializes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when no military time is given' do
      let(:military_time) { nil }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(/must include military_time/)
      end
    end

    context 'when no effort is given' do
      let(:effort) { nil }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(/must include effort/)
      end
    end

    context 'when no time_point is given' do
      let(:time_point) { nil }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(/must include time_point/)
      end
    end
  end

  describe '#day_and_time' do
    let(:effort) { build_stubbed(:effort, event: event, id: 101) }
    let(:event) { build_stubbed(:event, home_time_zone: 'Mountain Time (US & Canada)', start_time_in_home_zone: '2016-07-01 06:00:00') }
    let(:home_time_zone) { event.home_time_zone }
    let(:start_time) { event.start_time }
    let(:time_point) { TimePoint.new(1, 44, 1) }
    let(:prior_valid_split_time) { build_stubbed(:split_time, time_point: time_point, absolute_time: start_time) }
    let(:expected_time) { ActiveSupport::TimeZone[home_time_zone].parse(expected_time_string) }

    before { FactoryBot.reload }

    context 'if military_time provided is blank' do
      let(:military_time) { '' }

      it 'returns nil' do
        expect(subject.day_and_time).to be_nil
      end
    end

    context 'for an effort that has not yet started' do
      context 'for a same-day time' do
        let(:military_time) { '9:30:45' }
        let(:expected_time_from_prior) { 3.hours }
        let(:expected_time_string) { '2016-07-01 09:30:45' }

        it 'calculates the likely intended day and time' do
          expect(subject.day_and_time).to eq(expected_time)
        end
      end

      context 'for a multi-day time' do
        let(:military_time) { '15:30:45' }
        let(:expected_time_from_prior) { 50.hours }
        let(:expected_time_string) { '2016-07-03 15:30:45' }

        it 'calculates the likely intended day and time' do
          expect(subject.day_and_time).to eq(expected_time)
        end
      end

      context 'for a many-day time' do
        let(:military_time) { '15:30:45' }
        let(:expected_time_from_prior) { 100.hours }
        let(:expected_time_string) { '2016-07-05 15:30:45' }

        it 'calculates the likely intended day and time' do
          expect(subject.day_and_time).to eq(expected_time)
        end
      end
    end

    context 'for an effort partially underway' do
      let(:split_times) { build_stubbed_list(:split_times_hardrock_43, 30, effort_id: 101) }
      let(:time_points) { split_times.map(&:time_point) }
      let(:splits) { build_stubbed_list(:splits_hardrock_ccw, 16, course_id: 10) }

      context 'for a short segment' do
        let(:time_point) { time_points[9] } # Burrows In
        let(:prior_valid_split_time) { split_times[8] } # Sherman Out
        let(:expected_time_from_prior) { 1.hour }

        context 'for a same-day time' do
          let(:military_time) { '18:00:00' }
          let(:expected_time_string) { '2016-07-01 18:00:00' }

          it 'calculates the likely intended day and time' do
            expect(subject.day_and_time).to eq(expected_time)
          end
        end

        context 'for a late evening time' do
          let(:military_time) { '20:30:00' }
          let(:expected_time_string) { '2016-07-01 20:30:00' }

          it 'calculates the likely intended day and time' do
            expect(subject.day_and_time).to eq(expected_time)
          end
        end

        context 'for a time that rolls into the next morning' do
          let(:military_time) { '1:00:00' }
          let(:expected_time_string) { '2016-07-02 01:00:00' }

          it 'calculates the likely intended day and time' do
            expect(subject.day_and_time).to eq(expected_time)
          end
        end

        context 'for a time well into the next morning' do
          let(:military_time) { '5:30:00' }
          let(:expected_time_string) { '2016-07-02 05:30:00' }

          it 'calculates the likely intended day and time' do
            expect(subject.day_and_time).to eq(expected_time)
          end
        end
      end

      context 'for a longer segment' do
        let(:time_point) { time_points[13] } # Engineer In
        let(:prior_valid_split_time) { split_times[8] } # Sherman Out
        let(:expected_time_from_prior) { 8.hours }

        context 'for a time near midnight' do
          let(:military_time) { '23:30:00' }
          let(:expected_time_string) { '2016-07-01 23:30:00' }

          it 'calculates the likely intended day and time' do
            expect(subject.day_and_time).to eq(expected_time)
          end
        end

        context 'for a time past midnight the next day' do
          let(:military_time) { '00:30:00' }
          let(:expected_time_string) { '2016-07-02 00:30:00' }

          it 'calculates the likely intended day and time' do
            expect(subject.day_and_time).to eq(expected_time)
          end
        end

        context 'for a time in the early morning the next day' do
          let(:military_time) { '5:30:00' }
          let(:expected_time_string) { '2016-07-02 05:30:00' }

          it 'calculates the likely intended day and time' do
            expect(subject.day_and_time).to eq(expected_time)
          end
        end

        context 'for a time in the mid morning the next day' do
          let(:military_time) { '9:30:00' }
          let(:expected_time_string) { '2016-07-02 09:30:00' }

          it 'calculates the likely intended day and time' do
            expect(subject.day_and_time).to eq(expected_time)
          end
        end
      end

      context 'when the calculated time is more than three hours before the prior valid time' do
        let(:time_point) { time_points[1] } # Cunningham In
        let(:prior_valid_split_time) { split_times[0] } # Start
        let(:expected_time_from_prior) { 2.5.hours }
        let(:military_time) { '02:30:00' } # Expected time is roughly 08:30 on 7/1, so this would normally be interpreted as 02:30 on 7/1
        let(:expected_time_string) { '2016-07-02 02:30:00' }

        it 'adds a day' do
          expect(subject.day_and_time).to eq(expected_time)
        end
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
