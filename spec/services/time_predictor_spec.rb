# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TimePredictor do
  subject { TimePredictor.new(segment: segment, effort: effort, lap_splits: lap_splits,
                              completed_split_time: completed_split_time) }
  let(:segment) { build(:segment) }
  let(:lap_splits) { event.required_lap_splits }
  let(:completed_split_time) { subject_split_times.last }

  let(:distance_factor) { SegmentTimeCalculator::DISTANCE_FACTOR }
  let(:vert_gain_factor) { SegmentTimeCalculator::UP_VERT_GAIN_FACTOR }
  let(:event) { events(:sum_55k) }
  let(:effort) { efforts(:sum_55k_progress_rolling) }
  let(:subject_split_times) { effort.split_times }
  let(:ordered_splits) { event.ordered_splits }
  let(:start) { ordered_splits.first }
  let(:aid_1) { ordered_splits.second }
  let(:aid_2) { ordered_splits.third }
  let(:aid_5) { ordered_splits.fourth }
  let(:aid_6) { ordered_splits.fifth }
  let(:finish) { ordered_splits.last }

  let(:zero_start) { build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                           end_lap: 1, end_split: start, end_in_out: 'in') }
  let(:aid_1_in_to_aid_1_in) { build(:segment, begin_lap: 1, begin_split: aid_1, begin_in_out: 'in',
                                     end_lap: 1, end_split: aid_1, end_in_out: 'in') }
  let(:in_aid_2) { build(:segment, begin_lap: 1, begin_split: aid_2, begin_in_out: 'in',
                         end_lap: 1, end_split: aid_2, end_in_out: 'out') }
  let(:start_to_aid_1) { build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                               end_lap: 1, end_split: aid_1, end_in_out: 'in') }
  let(:start_to_aid_2) { build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                               end_lap: 1, end_split: aid_2, end_in_out: 'in') }
  let(:aid_1_to_aid_2_inclusive) { build(:segment, begin_lap: 1, begin_split: aid_1, begin_in_out: 'in',
                                         end_lap: 1, end_split: aid_2, end_in_out: 'out') }
  let(:aid_1_to_aid_5) { build(:segment, begin_lap: 1, begin_split: aid_1, begin_in_out: 'out',
                               end_lap: 1, end_split: aid_5, end_in_out: 'in') }
  let(:aid_2_to_aid_5) { build(:segment, begin_lap: 1, begin_split: aid_2, begin_in_out: 'out',
                               end_lap: 1, end_split: aid_5, end_in_out: 'in') }
  let(:aid_1_to_aid_2) { build(:segment, begin_lap: 1, begin_split: aid_1, begin_in_out: 'out',
                               end_lap: 1, end_split: finish, end_in_out: 'in') }
  let(:start_to_aid_5) { build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                               end_lap: 1, end_split: aid_5, end_in_out: 'in') }
  let(:start_to_finish) { build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                end_lap: 1, end_split: finish, end_in_out: 'in') }
  let(:start_to_completed) { build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                   end_lap: completed_split_time.lap, end_split: completed_split_time.split,
                                   end_in_out: SubSplit.kind(completed_split_time.bitkey)) }

  let(:pace_factor) { subject.send(:pace_factor) }

  describe '#initialize' do
    context 'with a segment, lap_splits, and completed_split_time in an args hash' do
      it 'initializes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when no segment is given' do
      let(:segment) { nil }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(/must include segment/)
      end
    end

    context 'when no effort is given' do
      let(:effort) { nil }
      let(:subject_split_times) { [] }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(/must include effort/)
      end
    end
  end

  describe '#segment_time' do
    context 'for a partially completed effort' do
      let(:completed_split_time) { subject_split_times.first(5).last }

      context 'for a zero start segment' do
        let(:segment) { zero_start }

        it 'predicts zero time' do
          expect(subject.segment_time).to eq(0)
        end
      end

      context 'for a zero intermediate segment' do
        let(:segment) { aid_1_in_to_aid_1_in }

        it 'predicts zero time' do
          expect(subject.segment_time).to eq(0)
        end
      end

      context 'for a segment in aid' do
        let(:segment) { in_aid_2 }

        it 'predicts 0 seconds' do
          expect(subject.segment_time).to eq(0)
        end
      end

      context 'for the segment beginning with start and ending with the completed split time' do
        let(:segment) { start_to_completed }

        it 'predicts the actual segment time' do
          expect(subject.segment_time).to eq(completed_split_time.time_from_start)
        end
      end

      context 'for a segment beginning with start and ending before the completed split time' do
        let(:segment) { start_to_aid_1 }

        it 'predicts the correct segment time taking pace factor into account' do
          expect(pace_factor).to be_within(0.1).of(0.60)
          expect(subject.segment_time).to be_within(100).of(8200)
        end
      end

      context 'for a segment beginning with start and ending after the completed split time' do
        let(:segment) { start_to_aid_2 }

        it 'predicts the correct segment time' do
          expect(subject.segment_time).to be_within(100).of(15_300)
        end
      end

      context 'for a segment starting before the completed split time and ending at the completed split time' do
        let(:segment) { aid_1_to_aid_2_inclusive }

        it 'predicts the correct segment time' do
          expect(subject.segment_time).to be_within(100).of(7100)
        end
      end

      context 'for a segment starting at the completed split time and ending after the completed split time' do
        let(:segment) { aid_2_to_aid_5 }

        it 'predicts the correct segment time' do
          expect(subject.segment_time).to be_within(100).of(2000)
        end
      end

      context 'for a segment starting before the completed split time and ending after the completed split time' do
        let(:segment) { aid_1_to_aid_5 }

        it 'predicts the correct segment time' do
          expect(subject.segment_time).to be_within(100).of(9100)
        end
      end

      context 'for a segment containing the entire course' do
        let(:segment) { start_to_finish }

        it 'predicts the correct segment time' do
          expect(subject.segment_time).to be_within(100).of(23_500)
        end
      end
    end

    context 'for an unstarted effort' do
      let(:completed_split_time) { subject_split_times.first }

      context 'for a zero segment' do
        let(:segment) { zero_start }

        it 'predicts zero time' do
          expect(subject.segment_time).to eq(0)
        end
      end
    end
  end

  describe '#data_status' do
    let(:completed_split_time) { subject_split_times.first(5).last }
    let(:completed_segment) { start_to_completed }
    let(:limit_factors) { DataStatus::LIMIT_FACTORS }
    let(:typical_time_in_aid) { DataStatus::TYPICAL_TIME_IN_AID }
    let(:typical_time) { segment.distance * distance_factor + segment.vert_gain * vert_gain_factor }
    let(:course) { event.course }

    context 'for a zero segment' do
      let(:segment) { zero_start }

      it 'sends to DataStatus a limits hash containing all zeros' do
        expected = {low_bad: 0, low_questionable: 0, high_questionable: 0, high_bad: 0}
        verify_data_status(segment, expected)
      end
    end

    context 'for an in_aid segment' do
      let(:segment) { in_aid_2 }
      let(:typical_time) { typical_time_in_aid }

      it 'sends to DataStatus a limits hash containing zeros for low limits and pace-adjusted times for high limits' do
        expected = [:low_bad, :low_questionable, :high_questionable, :high_bad]
                       .map { |limit| [limit, (typical_time * limit_factors[:in_aid][limit] * imputed_pace).to_i] }
                       .to_h
        verify_data_status(segment, expected)
      end
    end

    context 'for an inter-split segment' do
      let(:segment) { start_to_aid_2 }

      it 'sends to DataStatus a limits hash containing pace-adjusted times for all limits' do
        expected = [:low_bad, :low_questionable, :high_questionable, :high_bad]
                       .map { |limit| [limit, (typical_time * limit_factors[:terrain][limit] * imputed_pace).to_i] }
                       .to_h
        verify_data_status(segment, expected)
      end
    end

    context 'for a segment covering the entire course' do
      let(:segment) { start_to_finish }

      it 'sends to DataStatus a limits hash containing pace-adjusted times for all limits' do
        expected = [:low_bad, :low_questionable, :high_questionable, :high_bad]
                       .map { |limit| [limit, (typical_time * limit_factors[:terrain][limit] * imputed_pace).to_i] }
                       .to_h
        verify_data_status(segment, expected)
      end
    end

    def verify_data_status(segment, expected)
      seconds = 999
      allow(DataStatus).to receive(:determine)
      TimePredictor.new(segment: segment,
                        effort: effort,
                        lap_splits: lap_splits,
                        completed_split_time: completed_split_time,
                        calc_model: :terrain).data_status(seconds)
      expect(DataStatus).to have_received(:determine).with(a_hash_approximating(expected, 10), seconds)
    end

    def imputed_pace
      completed_typical_time = completed_segment.distance * distance_factor + completed_segment.vert_gain * vert_gain_factor
      completed_split_time.time_from_start / completed_typical_time
    end
  end
end
