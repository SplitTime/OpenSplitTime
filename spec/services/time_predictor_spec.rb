require 'rails_helper'

RSpec.describe TimePredictor do
  before { FactoryBot.reload }

  let(:distance_factor) { SegmentTimeCalculator::DISTANCE_FACTOR }
  let(:vert_gain_factor) { SegmentTimeCalculator::VERT_GAIN_FACTOR }
  let(:test_event) { build_stubbed(:event_functional, laps_required: 3, splits_count: 4, efforts_count: 1) }
  let(:test_effort) { test_event.efforts.first }
  let(:test_split_times) { test_effort.split_times }
  let(:start) { test_event.splits.first }
  let(:aid_1) { test_event.splits.second }
  let(:aid_2) { test_event.splits.third }
  let(:finish) { test_event.splits.last }
  let(:lap_1_zero_start) { build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                 end_lap: 1, end_split: start, end_in_out: 'in') }
  let(:aid_1_in_to_aid_1_in) { build(:segment, begin_lap: 1, begin_split: aid_1, begin_in_out: 'in',
                                     end_lap: 1, end_split: aid_1, end_in_out: 'in') }
  let(:lap_1_in_aid_2) { build(:segment, begin_lap: 1, begin_split: aid_2, begin_in_out: 'in',
                               end_lap: 1, end_split: aid_2, end_in_out: 'out') }
  let(:lap_1_start_to_lap_1_aid_1) { build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                           end_lap: 1, end_split: aid_1, end_in_out: 'in') }
  let(:lap_1_start_to_lap_1_finish) { build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                            end_lap: 1, end_split: finish, end_in_out: 'in') }
  let(:lap_1_aid_1_to_lap_1_aid_2_inclusive) { build(:segment, begin_lap: 1, begin_split: aid_1, begin_in_out: 'in',
                                                     end_lap: 1, end_split: aid_2, end_in_out: 'out') }
  let(:lap_1_aid_2_to_lap_1_finish) { build(:segment, begin_lap: 1, begin_split: aid_2, begin_in_out: 'out',
                                            end_lap: 1, end_split: finish, end_in_out: 'in') }
  let(:lap_1_aid_1_to_lap_1_finish) { build(:segment, begin_lap: 1, begin_split: aid_1, begin_in_out: 'out',
                                            end_lap: 1, end_split: finish, end_in_out: 'in') }
  let(:lap_1_start_to_lap_2_aid_1) { build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                           end_lap: 2, end_split: aid_1, end_in_out: 'in') }
  let(:lap_1_start_to_lap_3_finish) { build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                            end_lap: 3, end_split: finish, end_in_out: 'in') }
  let(:lap_1_start_to_completed) { build(:segment, begin_lap: 1, begin_split: start, begin_in_out: 'in',
                                         end_lap: completed_split_time.lap, end_split: completed_split_time.split,
                                         end_in_out: SubSplit.kind(completed_split_time.bitkey)) }

  describe '#initialize' do
    it 'initializes with a segment, lap_splits, and completed_split_time in an args hash' do
      segment = build(:segment)
      lap_splits, _ = lap_splits_and_time_points(test_event)
      completed_split_time = test_split_times.last
      expect { TimePredictor.new(segment: segment,
                                 lap_splits: lap_splits,
                                 completed_split_time: completed_split_time) }
          .not_to raise_error
    end

    it 'raises an ArgumentError if no segment is given' do
      lap_splits, _ = lap_splits_and_time_points(test_event)
      completed_split_time = test_split_times.last
      expect { TimePredictor.new(lap_splits: lap_splits,
                                 completed_split_time: completed_split_time) }
          .to raise_error(/must include segment/)
    end

    it 'raises an ArgumentError if no effort or lap_splits are given' do
      segment = build(:segment)
      completed_split_time = test_split_times.last
      expect { TimePredictor.new(segment: segment,
                                 completed_split_time: completed_split_time) }
          .to raise_error(/must include one of effort or lap_splits and completed_split_time/)
    end

    it 'raises an ArgumentError if no effort or completed_split_time are given' do
      segment = build(:segment)
      lap_splits, _ = lap_splits_and_time_points(test_event)
      expect { TimePredictor.new(segment: segment, lap_splits: lap_splits) }
          .to raise_error(/must include one of effort or lap_splits and completed_split_time/)
    end
  end

  describe '#segment_time' do
    context 'for a partially completed effort' do
      let(:completed_split_time) { test_split_times.first(5).last }

      it 'predicts zero time for a zero start segment' do
        segment = lap_1_zero_start
        expected = 0
        verify_segment_time(segment, expected)
      end

      it 'predicts zero time for a zero intermediate segment' do
        segment = aid_1_in_to_aid_1_in
        expected = 0
        verify_segment_time(segment, expected)
      end

      it 'predicts zero time for a a segment in aid' do
        segment = lap_1_in_aid_2
        expected = 0
        verify_segment_time(segment, expected)
      end

      it 'predicts the actual segment time for the segment beginning with start and ending with the completed split time' do
        segment = lap_1_start_to_completed
        expected = completed_split_time.time_from_start
        verify_segment_time(segment, expected)
      end

      it 'predicts the correct segment time for a segment beginning with start and ending before the completed split time' do
        segment = lap_1_start_to_lap_1_aid_1
        expected = 6300
        verify_segment_time(segment, expected)
      end

      it 'predicts the correct segment time for a segment beginning with start and ending after the completed split time' do
        segment = lap_1_start_to_lap_1_finish
        expected = 18900
        verify_segment_time(segment, expected)
      end

      it 'functions properly for segments starting before the completed split time and ending at the completed split time' do
        segment = lap_1_aid_1_to_lap_1_aid_2_inclusive
        expected = 6300
        verify_segment_time(segment, expected)
      end

      it 'functions properly for segments starting at the completed split time and ending after the completed split time' do
        segment = lap_1_aid_2_to_lap_1_finish
        expected = 6300
        verify_segment_time(segment, expected)
      end

      it 'functions properly for segments starting before the completed split time and ending after the completed split time' do
        segment = lap_1_aid_1_to_lap_1_finish
        expected = 12600
        verify_segment_time(segment, expected)
      end

      it 'functions properly for segments starting on one lap and ending on another' do
        segment = lap_1_start_to_lap_2_aid_1
        expected = 25200
        verify_segment_time(segment, expected)
      end

      it 'functions properly for segments containing multiple finished laps' do
        segment = lap_1_start_to_lap_3_finish
        expected = 56700
        verify_segment_time(segment, expected)
      end
    end

    context 'for an unstarted effort' do
      let(:completed_split_time) { test_split_times.first }

      it 'predicts zero time for a zero segment' do
        segment = lap_1_zero_start
        expected = 0
        verify_segment_time(segment, expected)
      end
    end

    def verify_segment_time(segment, expected)
      course = test_event.course
      allow(course).to receive(:distance).and_return(finish.distance_from_start)
      allow(course).to receive(:vert_gain).and_return(finish.vert_gain_from_start)
      allow(course).to receive(:vert_loss).and_return(finish.vert_loss_from_start)
      lap_splits, _ = lap_splits_and_time_points(test_event)
      [segment.end_lap_split, segment.begin_lap_split]
          .each { |lap_split| allow(lap_split).to receive(:course).and_return(course) }
      margin = expected * 0.01
      predictor = TimePredictor.new(segment: segment,
                                    effort: test_effort,
                                    lap_splits: lap_splits,
                                    completed_split_time: completed_split_time,
                                    calc_model: :terrain)
      expect(predictor.segment_time).to be_within(margin).of(expected)
    end
  end

  describe '#data_status' do
    let(:completed_split_time) { test_split_times.first(5).last }
    let(:completed_segment) { lap_1_start_to_completed }
    let(:limit_factors) { DataStatus::LIMIT_FACTORS }
    let(:typical_time_in_aid) { DataStatus::TYPICAL_TIME_IN_AID }

    it 'for a zero segment, sends to DataStatus a limits hash containing all zeros' do
      segment = lap_1_zero_start
      expected = {low_bad: 0, low_questionable: 0, high_questionable: 0, high_bad: 0}
      verify_data_status(segment, expected)
    end

    it 'for an in_aid segment, sends to DataStatus a limits hash containing zeros for low limits and pace-adjusted times for high limits' do
      imputed_pace = imputed_pace(completed_segment)
      segment = lap_1_in_aid_2
      typical_time = typical_time_in_aid
      expected = [:low_bad, :low_questionable, :high_questionable, :high_bad]
                     .map { |limit| [limit, (typical_time * limit_factors[:in_aid][limit] * imputed_pace).to_i] }
                     .to_h
      verify_data_status(segment, expected)
    end

    it 'for an inter-split segment, sends to DataStatus a limits hash containing pace-adjusted times for all limits' do
      imputed_pace = imputed_pace(completed_segment)
      segment = lap_1_start_to_lap_1_finish
      typical_time = segment.distance * distance_factor + segment.vert_gain * vert_gain_factor
      expected = [:low_bad, :low_questionable, :high_questionable, :high_bad]
                     .map { |limit| [limit, (typical_time * limit_factors[:terrain][limit] * imputed_pace).to_i] }
                     .to_h
      verify_data_status(segment, expected)
    end

    it 'for a segment covering multiple laps, sends to DataStatus a limits hash containing pace-adjusted times for all limits' do
      imputed_pace = imputed_pace(completed_segment)
      segment = lap_1_start_to_lap_3_finish
      typical_time = segment.distance * distance_factor + segment.vert_gain * vert_gain_factor
      expected = [:low_bad, :low_questionable, :high_questionable, :high_bad]
                     .map { |limit| [limit, (typical_time * limit_factors[:terrain][limit] * imputed_pace).to_i] }
                     .to_h
      verify_data_status(segment, expected)
    end

    def verify_data_status(segment, expected)
      course = test_event.course
      allow(course).to receive(:distance).and_return(finish.distance_from_start)
      allow(course).to receive(:vert_gain).and_return(finish.vert_gain_from_start)
      allow(course).to receive(:vert_loss).and_return(finish.vert_loss_from_start)
      lap_splits, _ = lap_splits_and_time_points(test_event)
      [segment.end_lap_split, segment.begin_lap_split]
          .each { |lap_split| allow(lap_split).to receive(:course).and_return(course) }
      seconds = 999
      allow(DataStatus).to receive(:determine)
      TimePredictor.new(segment: segment,
                        effort: test_effort,
                        lap_splits: lap_splits,
                        completed_split_time: completed_split_time,
                        calc_model: :terrain).data_status(seconds)
      expect(DataStatus).to have_received(:determine).with(expected, seconds)
    end

    def imputed_pace(segment)
      course = test_event.course
      allow(course).to receive(:distance).and_return(finish.distance_from_start)
      allow(course).to receive(:vert_gain).and_return(finish.vert_gain_from_start)
      allow(course).to receive(:vert_loss).and_return(finish.vert_loss_from_start)
      [segment.end_lap_split, segment.begin_lap_split]
          .each { |lap_split| allow(lap_split).to receive(:course).and_return(course) }
      completed_typical_time = completed_segment.distance * distance_factor + completed_segment.vert_gain * vert_gain_factor
      completed_split_time.time_from_start / completed_typical_time
    end
  end
end
