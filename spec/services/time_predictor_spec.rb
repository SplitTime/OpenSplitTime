require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe TimePredictor do

  let(:distance_factor) { SegmentTimeCalculator::DISTANCE_FACTOR }
  let(:lap_1) { 1 }
  let(:lap_2) { 2 }
  let(:test_event) { FactoryGirl.build_stubbed(:event_functional, laps_required: 3, splits_count: 4, efforts_count: 1) }
  let(:test_effort) { test_event.efforts.first }
  let(:test_split_times) { test_effort.split_times }
  let(:start) { event.splits.first }
  let(:aid_1) { event.splits.second }
  let(:aid_2) { event.splits.third }
  let(:finish) { event.splits.last }

  let(:zero_start) { Segment.new(begin_sub_split: split1.sub_split_in, end_sub_split: split1.sub_split_in,
                                 begin_split: split1, end_split: split1) }
  let(:zero_intermediate) { Segment.new(begin_sub_split: split2.sub_split_in, end_sub_split: split2.sub_split_in,
                                        begin_split: split2, end_split: split2) }
  let(:start_to_split_2_in) { Segment.new(begin_sub_split: split1.sub_split_in, end_sub_split: split2.sub_split_in,
                                          begin_split: split1, end_split: split2) }
  let(:start_to_split_3_out) { Segment.new(begin_sub_split: split1.sub_split_in, end_sub_split: split3.sub_split_out,
                                           begin_split: split1, end_split: split3) }
  let(:start_to_split_4_in) { Segment.new(begin_sub_split: split1.sub_split_in, end_sub_split: split4.sub_split_in,
                                          begin_split: split1, end_split: split4) }
  let(:start_to_finish) { Segment.new(begin_sub_split: split1.sub_split_in, end_sub_split: split6.sub_split_in,
                                      begin_split: split1, end_split: split6) }
  let(:split_2_out_to_split_3_out) { Segment.new(begin_sub_split: split2.sub_split_out, end_sub_split: split3.sub_split_out,
                                                 begin_split: split2, end_split: split3) }
  let(:split_2_out_to_split_4_in) { Segment.new(begin_sub_split: split2.sub_split_out, end_sub_split: split4.sub_split_in,
                                                begin_split: split2, end_split: split4) }
  let(:split_3_out_to_split_4_in) { Segment.new(begin_sub_split: split3.sub_split_out, end_sub_split: split4.sub_split_in,
                                                begin_split: split3, end_split: split4) }
  let(:in_split_2) { Segment.new(begin_sub_split: split2.sub_split_in, end_sub_split: split2.sub_split_out,
                                 begin_split: split2, end_split: split2) }

  describe '#initialize' do
    it 'initializes with a segment, lap_splits, and completed_split_time in an args hash' do
      segment = build_segment(lap_1, start, 'in', lap_1, aid_2, 'in')
      completed_split_time = split_times_101.last
      expect { TimePredictor.new(segment: segment,
                                 ordered_splits: ordered_splits,
                                 completed_split_time: completed_split_time) }.not_to raise_error
    end

    def build_segment(begin_lap, begin_split, begin_in_out, end_lap, end_split, end_in_out)
      begin_point = TimePoint.new(begin_lap, begin_split.id, SubSplit.bitkey(begin_in_out))
      end_point = TimePoint.new(end_lap, end_split.id, SubSplit.bitkey(end_in_out))
      begin_lap_split = LapSplit.new(begin_lap, begin_split)
      end_lap_split = LapSplit.new(end_lap, end_split)
      Segment.new(begin_point: begin_point, end_point: end_point,
                  begin_lap_split: begin_lap_split, end_lap_split: end_lap_split)
    end

    it 'raises an ArgumentError if no segment is given' do
      completed_split_time = split_times_101.last
      expect { TimePredictor.new(ordered_splits: ordered_splits, completed_split_time: completed_split_time) }
          .to raise_error(/must include segment/)
    end

    it 'raises an ArgumentError if no effort or ordered_splits are given' do
      segment = start_to_split_2_in
      completed_split_time = split_times_101.last
      expect { TimePredictor.new(segment: segment, completed_split_time: completed_split_time) }
          .to raise_error(/must include one of effort or ordered_splits and completed_split_time/)
    end

    it 'raises an ArgumentError if no effort or completed_split_time are given' do
      segment = start_to_split_2_in
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      expect { TimePredictor.new(segment: segment, ordered_splits: ordered_splits) }
          .to raise_error(/must include one of effort or ordered_splits and completed_split_time/)
    end
  end

  describe '#segment_time' do
    context 'for a partially completed effort' do
      let(:completed_split_time) { test_split_times.first(5).last }

      it 'predicts zero time for a zero start segment' do
        segment = zero_start
        expected = 0
        verify_segment_time(segment, expected)
      end

      it 'predicts zero time for a zero intermediate segment' do
        segment = zero_intermediate
        expected = 0
        verify_segment_time(segment, expected)
      end

      it 'predicts zero time for a a segment in aid' do
        segment = in_split_2
        expected = 0
        verify_segment_time(segment, expected)
      end

      it 'predicts the actual segment time for the segment beginning with start and ending with the completed split time' do
        segment = start_to_split_3_out
        expected = 2100
        verify_segment_time(segment, expected)
      end

      it 'predicts the correct segment time for a segment beginning with start and ending before the completed split time' do
        segment = start_to_split_2_in
        expected = 1050
        verify_segment_time(segment, expected)
      end

      it 'predicts the correct segment time for a segment beginning with start and ending after the completed split time' do
        segment = start_to_split_4_in
        expected = 3150
        verify_segment_time(segment, expected)
      end

      it 'functions properly for sub_splits starting before the completed split time and ending at the completed split time' do
        segment = split_2_out_to_split_3_out
        expected = 1050
        verify_segment_time(segment, expected)
      end

      it 'functions properly for sub_splits starting at the completed split time and ending after the completed split time' do
        segment = split_3_out_to_split_4_in
        expected = 1050
        verify_segment_time(segment, expected)
      end

      it 'functions properly for sub_splits starting before the completed split time and ending after the completed split time' do
        segment = split_2_out_to_split_4_in
        expected = 2100
        verify_segment_time(segment, expected)
      end
    end

    context 'for an unstarted effort' do
      let(:completed_split_time) { test_split_times.first }

      it 'predicts zero time for a zero segment' do
        segment = zero_start
        expected = 0
        verify_segment_time(segment, expected)
      end
    end

    def verify_segment_time(segment, expected)
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
    let(:completed_split_time) { split_times_101.first(5).last }
    let(:completed_segment) { start_to_split_3_out }
    let(:completed_distance) { completed_segment.distance }
    let(:completed_typical_time) { completed_distance * distance_factor }
    let(:imputed_pace) { completed_split_time.time_from_start / completed_typical_time }
    let(:limit_factors) { DataStatus::LIMIT_FACTORS }
    let(:typical_time_in_aid) { DataStatus::TYPICAL_TIME_IN_AID }

    it 'for a zero segment, sends to DataStatus a limits hash containing all zeros' do
      segment = zero_start
      expected = {low_bad: 0, low_questionable: 0, high_questionable: 0, high_bad: 0}
      verify_data_status(segment, expected)
    end

    it 'for an in_aid segment, sends to DataStatus a limits hash containing zeros for low limits and pace-adjusted times for high limits' do
      segment = in_split_2
      typical_time = typical_time_in_aid
      expected = [:low_bad, :low_questionable, :high_questionable, :high_bad]
                     .map { |limit| [limit, typical_time * limit_factors[:in_aid][limit] * imputed_pace] }
                     .to_h
      verify_data_status(segment, expected)
    end

    it 'for an inter-split segment, sends to DataStatus a limits hash containing pace-adjusted times for all limits' do
      segment = start_to_finish
      typical_time = start_to_finish.distance * distance_factor
      expected = [:low_bad, :low_questionable, :high_questionable, :high_bad]
                     .map { |limit| [limit, typical_time * limit_factors[:terrain][limit] * imputed_pace] }
                     .to_h
      verify_data_status(segment, expected)
    end

    def verify_data_status(segment, expected)
      seconds = 999
      allow(DataStatus).to receive(:determine)
      TimePredictor.new(segment: segment,
                        effort: effort,
                        ordered_splits: ordered_splits,
                        completed_split_time: completed_split_time,
                        calc_model: :terrain).data_status(seconds)
      expect(DataStatus).to have_received(:determine).with(expected, seconds)
    end
  end
end