# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IntendedTimeCalculator do
  subject { IntendedTimeCalculator.new(effort: effort,
                                       military_time: military_time,
                                       time_point: time_point,
                                       prior_valid_split_time: prior_valid_split_time) }
  let(:event) { effort.event }
  let(:home_time_zone) { event.home_time_zone }
  let(:start_time) { event.start_time }
  let(:time_points) { event.required_time_points }
  let(:time_point) { time_points.second }
  let(:military_time) { '15:30:45' }
  let(:prior_valid_split_time) { effort.ordered_split_times.last }

  describe '#initialize' do
    let(:effort) { efforts(:hardrock_2014_not_started) }

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
      let(:time_point) { TimePoint.new(1, 101, 1) }
      let(:prior_valid_split_time) { SplitTime.new }

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

  describe '#absolute_time_local' do
    let(:expected_time) { expected_time_string.in_time_zone(home_time_zone) }

    context 'if military_time provided is blank' do
      let(:effort) { efforts(:hardrock_2014_not_started) }
      let(:military_time) { '' }
      let(:time_point) { event.required_time_points.second }

      it 'returns nil' do
        expect(subject.absolute_time_local).to be_nil
      end
    end

    context 'for an effort that has not yet started' do
      let(:effort) { efforts(:hardrock_2014_not_started) }

      context 'for a same-day time' do
        let(:time_point) { event.required_time_points.second }
        let(:military_time) { '9:30:45' }
        let(:expected_time_string) { '2014-07-11 09:30:45' }

        it 'calculates the likely intended day and time' do
          expect(subject.absolute_time_local).to eq(expected_time)
        end
      end

      context 'for a time extending into the next day' do
        let(:time_point) { event.required_time_points[7] } # Sherman In
        let(:military_time) { '10:30:45' }
        let(:expected_time_string) { '2014-07-12 10:30:45' }

        it 'calculates the likely intended day and time' do
          expect(subject.absolute_time_local).to eq(expected_time)
        end
      end

      context 'for a multi-day time' do
        let(:time_point) { event.required_time_points.last } # Finish
        let(:military_time) { '02:30:45' }
        let(:expected_time_string) { '2014-07-13 02:30:45' }

        it 'calculates the likely intended day and time' do
          expect(subject.absolute_time_local).to eq(expected_time)
        end
      end
    end

    context 'for an effort partially underway' do
      let(:effort) { efforts(:hardrock_2016_progress_sherman) }

      context 'for a shorter segment and a same-day time' do
        let(:prior_valid_split_time) { effort.ordered_split_times[2] } # Telluride Out
        let(:time_point) { time_points[3] } # Ouray In
        let(:military_time) { '18:00:00' }
        let(:expected_time_string) { '2016-07-15 18:00:00' }

        it 'calculates the likely intended day and time' do
          expect(subject.absolute_time_local).to eq(expected_time)
        end
      end

      context 'for a shorter segment with a time that rolls into the next morning' do
        let(:prior_valid_split_time) { effort.ordered_split_times[6] } # Grouse Out
        let(:time_point) { time_points[7] } # Sherman In
        let(:military_time) { '1:00:00' }
        let(:expected_time_string) { '2016-07-16 01:00:00' }

        it 'calculates the likely intended day and time' do
          expect(subject.absolute_time_local).to eq(expected_time)
        end
      end

      context 'for a long segment with a time well into the next day' do
        let(:prior_valid_split_time) { effort.ordered_split_times[2] } # Telluride Out
        let(:time_point) { time_points[9] } # Cunningham In
        let(:military_time) { '15:00:00' }
        let(:expected_time_string) { '2016-07-16 15:00:00' }

        it 'calculates the likely intended day and time' do
          expect(subject.absolute_time_local).to eq(expected_time)
        end
      end

      context 'when the calculated time is more than three hours before the prior valid time' do
        let(:prior_valid_split_time) { effort.ordered_split_times[0] } # Start
        let(:time_point) { time_points[1] } # Telluride In
        let(:military_time) { '02:30:00' } # Expected time is roughly 14:00 on 7/15, so this would normally be interpreted as 02:30 on 7/15
        let(:expected_time_string) { '2016-07-16 02:30:00' }

        it 'adds a day' do
          expect(subject.absolute_time_local).to eq(expected_time)
        end
      end
    end

    context 'when the intended time occurs on the day that Daylight Savings Time switches' do
      let(:effort) { efforts(:sum_100k_on_dst_change) }
      let(:prior_valid_split_time) { effort.ordered_split_times.last }
      let(:time_points) { effort.event.required_time_points }
      let(:time_point) { time_points.elements_after(prior_valid_split_time.time_point).first }
      let(:military_time) { '09:30:00' }

      before { effort.event.update(start_time_local: start_time_local) }

      context 'when the event starts on a day before the DST change' do
        let(:start_time_local) { '2017-09-23 07:00:00' }
        let(:expected_time_string) { '2017-11-05 09:30:00' }

        it 'calculates intended day and time properly' do
          expect(subject.absolute_time_local).to eq(expected_time)
        end
      end

      context 'when the event starts before the DST change on the day of the DST change' do
        let(:start_time_local) { '2017-11-05 01:00:00' }
        let(:expected_time_string) { '2017-11-05 09:30:00' }

        it 'calculates intended day and time properly' do
          expect(subject.absolute_time_local).to eq(expected_time)
        end
      end

      context 'when the event starts after the DST change' do
        let(:start_time_local) { '2017-11-05 07:00:00' }
        let(:expected_time_string) { '2017-11-05 09:30:00' }

        it 'calculates intended day and time properly' do
          expect(subject.absolute_time_local).to eq(expected_time)
        end
      end

      context 'when the effort starts before the DST change and the intended time is after' do
        let(:effort) { efforts(:sum_100k_across_dst_change) }
        let(:military_time) { '02:30:00' }
        let(:start_time_local) { '2017-11-05 00:30:00' }
        let(:expected_time_string) { '2017-11-05 02:30:00' }

        it 'calculates intended day and time properly' do
          expect(subject.absolute_time_local).to eq(expected_time)
        end
      end
    end

    context 'if military time is greater than 24 hours' do
      let(:military_time) { '25:30:45' }

      it 'raises a RangeError' do
        effort = build_stubbed(:effort)
        time_point = TimePoint.new(1, 45, 1)
        expected_time_from_prior = 90.minutes
        prior_valid_split_time = SplitTime.new

        expect { IntendedTimeCalculator.new(effort: effort,
                                            military_time: military_time,
                                            time_point: time_point,
                                            expected_time_from_prior: expected_time_from_prior,
                                            prior_valid_split_time: prior_valid_split_time) }
            .to raise_error(/improperly formatted/)
      end
    end
  end
end
