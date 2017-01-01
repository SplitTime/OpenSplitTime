require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe TimesPredictor do
  DISTANCE_FACTOR ||= SegmentTimeCalculator::DISTANCE_FACTOR

  let(:split_times_101) { FactoryGirl.build_stubbed_list(:split_times_in_out, 20, effort_id: 101).first(10) }
  let(:split_ids) { split_times_101.map(&:split_id).uniq }
  let(:split1) { FactoryGirl.build_stubbed(:start_split, id: split_ids[0], course_id: 10, distance_from_start: 0) }
  let(:split2) { FactoryGirl.build_stubbed(:split, id: split_ids[1], course_id: 10, distance_from_start: 1000) }
  let(:split3) { FactoryGirl.build_stubbed(:split, id: split_ids[2], course_id: 10, distance_from_start: 2000) }
  let(:split4) { FactoryGirl.build_stubbed(:split, id: split_ids[3], course_id: 10, distance_from_start: 3000) }
  let(:split5) { FactoryGirl.build_stubbed(:split, id: split_ids[4], course_id: 10, distance_from_start: 4000) }
  let(:split6) { FactoryGirl.build_stubbed(:finish_split, id: split_ids[5], course_id: 10, distance_from_start: 5000) }

  describe '#initialize' do

    it 'initializes with ordered_splits and working_split_time in an args hash' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      working_split_time = split_times_101.last
      expect { TimesPredictor.new(ordered_splits: ordered_splits,
                                  working_split_time: working_split_time) }.not_to raise_error
    end

    it 'raises an ArgumentError if no effort or ordered_splits are given' do
      working_split_time = split_times_101.last
      expect { TimesPredictor.new(working_split_time: working_split_time) }.to raise_error(/must include one of effort or ordered_splits and working_split_time/)
    end

    it 'raises an ArgumentError if no effort or working_split_time are given' do
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      expect { TimesPredictor.new(ordered_splits: ordered_splits) }.to raise_error(/must include one of effort or ordered_splits and working_split_time/)
    end
  end

  describe '#times_from_start' do
    before do
      FactoryGirl.reload
    end

    context 'for an unstarted effort' do
      it 'returns a hash containing elements corresponding to the sub_splits related to the effort.event' do
        effort = FactoryGirl.build_stubbed(:effort)
        ordered_splits = [split1, split2, split3, split4, split5, split6]
        sub_splits = ordered_splits.map(&:sub_splits).flatten
        working_split_time = nil
        predictor = TimesPredictor.new(effort: effort,
                                       ordered_splits: ordered_splits,
                                       working_split_time: working_split_time,
                                       calc_model: :terrain)
        expect(predictor.times_from_start.count).to eq(10)
        expect(predictor.times_from_start.keys).to eq(sub_splits)
      end

      it 'predicts zero time for start splits' do
        effort = FactoryGirl.build_stubbed(:effort)
        ordered_splits = [split1, split2, split3, split4, split5, split6]
        sub_splits = ordered_splits.map(&:sub_splits).flatten
        working_split_time = nil
        predictor = TimesPredictor.new(effort: effort,
                                       ordered_splits: ordered_splits,
                                       working_split_time: working_split_time,
                                       calc_model: :terrain)
        expect(predictor.times_from_start[sub_splits[0]]).to eq(0)
      end

      it 'predicts the correct expected time from start for later sub_splits using pace_factor == 1' do
        effort = FactoryGirl.build_stubbed(:effort)
        ordered_splits = [split1, split2, split3, split4, split5, split6]
        sub_splits = ordered_splits.map(&:sub_splits).flatten
        working_split_time = nil
        predictor = TimesPredictor.new(effort: effort,
                                       ordered_splits: ordered_splits,
                                       working_split_time: working_split_time,
                                       calc_model: :terrain)
        expect(predictor.times_from_start[sub_splits[1]]).to eq(split2.distance_from_start * DISTANCE_FACTOR)
        expect(predictor.times_from_start[sub_splits[2]]).to eq(split2.distance_from_start * DISTANCE_FACTOR)
        expect(predictor.times_from_start[sub_splits[3]]).to eq(split3.distance_from_start * DISTANCE_FACTOR)
        expect(predictor.times_from_start[sub_splits[4]]).to eq(split3.distance_from_start * DISTANCE_FACTOR)
        expect(predictor.times_from_start[sub_splits[5]]).to eq(split4.distance_from_start * DISTANCE_FACTOR)
        expect(predictor.times_from_start[sub_splits[6]]).to eq(split4.distance_from_start * DISTANCE_FACTOR)
        expect(predictor.times_from_start[sub_splits[7]]).to eq(split5.distance_from_start * DISTANCE_FACTOR)
        expect(predictor.times_from_start[sub_splits[8]]).to eq(split5.distance_from_start * DISTANCE_FACTOR)
        expect(predictor.times_from_start[sub_splits[9]]).to eq(split6.distance_from_start * DISTANCE_FACTOR)
      end
    end

    context 'for a partially completed effort' do
      it 'returns a hash containing elements corresponding to the sub_splits related to the effort.event' do
        effort = FactoryGirl.build_stubbed(:effort, id: 101)
        ordered_splits = [split1, split2, split3, split4, split5, split6]
        sub_splits = ordered_splits.map(&:sub_splits).flatten
        working_split_time = split_times_101.first(5).last
        predictor = TimesPredictor.new(effort: effort,
                                       ordered_splits: ordered_splits,
                                       working_split_time: working_split_time,
                                       calc_model: :terrain)
        expect(predictor.times_from_start.count).to eq(10)
        expect(predictor.times_from_start.keys).to eq(sub_splits)
      end

      it 'predicts zero time for start splits' do
        effort = FactoryGirl.build_stubbed(:effort, id: 101)
        ordered_splits = [split1, split2, split3, split4, split5, split6]
        sub_splits = ordered_splits.map(&:sub_splits).flatten
        working_split_time = split_times_101.first(5).last
        predictor = TimesPredictor.new(effort: effort,
                                       ordered_splits: ordered_splits,
                                       working_split_time: working_split_time,
                                       calc_model: :terrain)
        expect(predictor.times_from_start[sub_splits[0]]).to eq(0)
      end

      it 'predicts the actual time from start for the last valid sub_split recorded' do
        effort = FactoryGirl.build_stubbed(:effort, id: 101)
        ordered_splits = [split1, split2, split3, split4, split5, split6]
        sub_splits = ordered_splits.map(&:sub_splits).flatten
        working_split_time = split_times_101.first(5).last
        predictor = TimesPredictor.new(effort: effort,
                                       ordered_splits: ordered_splits,
                                       working_split_time: working_split_time,
                                       calc_model: :terrain)
        expect(predictor.times_from_start[sub_splits[4]]).to eq(2100)
      end

      it 'predicts the correct expected time from start for prior sub_splits using a calculated pace_factor' do
        effort = FactoryGirl.build_stubbed(:effort, id: 101)
        ordered_splits = [split1, split2, split3, split4, split5, split6]
        sub_splits = ordered_splits.map(&:sub_splits).flatten
        working_split_time = split_times_101.first(5).last
        predictor = TimesPredictor.new(effort: effort,
                                       ordered_splits: ordered_splits,
                                       working_split_time: working_split_time,
                                       calc_model: :terrain)
        expect(predictor.times_from_start[sub_splits[1]]).to be_within(50).of(1050)
        expect(predictor.times_from_start[sub_splits[2]]).to be_within(50).of(1050)
        expect(predictor.times_from_start[sub_splits[3]]).to be_within(50).of(2100)
      end

      it 'predicts the correct expected time from start for later sub_splits using a calculated pace_factor' do
        effort = FactoryGirl.build_stubbed(:effort, id: 101)
        ordered_splits = [split1, split2, split3, split4, split5, split6]
        sub_splits = ordered_splits.map(&:sub_splits).flatten
        working_split_time = split_times_101.first(5).last
        predictor = TimesPredictor.new(effort: effort,
                                       ordered_splits: ordered_splits,
                                       working_split_time: working_split_time,
                                       calc_model: :terrain)
        expect(predictor.times_from_start[sub_splits[5]]).to be_within(50).of(3150)
        expect(predictor.times_from_start[sub_splits[6]]).to be_within(50).of(3150)
        expect(predictor.times_from_start[sub_splits[7]]).to be_within(50).of(4200)
        expect(predictor.times_from_start[sub_splits[8]]).to be_within(50).of(4200)
        expect(predictor.times_from_start[sub_splits[9]]).to be_within(50).of(5250)
      end
    end

    context 'for a completed effort' do
      it 'returns a hash containing elements corresponding to the sub_splits related to the effort.event' do
        effort = FactoryGirl.build_stubbed(:effort, id: 101)
        ordered_splits = [split1, split2, split3, split4, split5, split6]
        sub_splits = ordered_splits.map(&:sub_splits).flatten
        working_split_time = split_times_101.last
        predictor = TimesPredictor.new(effort: effort,
                                       ordered_splits: ordered_splits,
                                       working_split_time: working_split_time,
                                       calc_model: :terrain)
        expect(predictor.times_from_start.count).to eq(10)
        expect(predictor.times_from_start.keys).to eq(sub_splits)
      end

      it 'predicts zero time for start splits' do
        effort = FactoryGirl.build_stubbed(:effort, id: 101)
        ordered_splits = [split1, split2, split3, split4, split5, split6]
        sub_splits = ordered_splits.map(&:sub_splits).flatten
        working_split_time = split_times_101.last
        predictor = TimesPredictor.new(effort: effort,
                                       ordered_splits: ordered_splits,
                                       working_split_time: working_split_time,
                                       calc_model: :terrain)
        expect(predictor.times_from_start[sub_splits[0]]).to eq(0)
      end

      it 'predicts the actual time from start for the finish sub_split' do
        effort = FactoryGirl.build_stubbed(:effort, id: 101)
        ordered_splits = [split1, split2, split3, split4, split5, split6]
        sub_splits = ordered_splits.map(&:sub_splits).flatten
        working_split_time = split_times_101.last
        predictor = TimesPredictor.new(effort: effort,
                                       ordered_splits: ordered_splits,
                                       working_split_time: working_split_time,
                                       calc_model: :terrain)
        expect(predictor.times_from_start[sub_splits[9]]).to eq(5000)
      end

      it 'predicts the correct expected time from start for prior sub_splits using a calculated pace_factor' do
        effort = FactoryGirl.build_stubbed(:effort, id: 101)
        ordered_splits = [split1, split2, split3, split4, split5, split6]
        sub_splits = ordered_splits.map(&:sub_splits).flatten
        working_split_time = split_times_101.last
        predictor = TimesPredictor.new(effort: effort,
                                       ordered_splits: ordered_splits,
                                       working_split_time: working_split_time,
                                       calc_model: :terrain)
        expect(predictor.times_from_start[sub_splits[1]]).to be_within(50).of(1000)
        expect(predictor.times_from_start[sub_splits[2]]).to be_within(50).of(1000)
        expect(predictor.times_from_start[sub_splits[3]]).to be_within(50).of(2000)
        expect(predictor.times_from_start[sub_splits[4]]).to be_within(50).of(2000)
        expect(predictor.times_from_start[sub_splits[5]]).to be_within(50).of(3000)
        expect(predictor.times_from_start[sub_splits[6]]).to be_within(50).of(3000)
        expect(predictor.times_from_start[sub_splits[7]]).to be_within(50).of(4000)
        expect(predictor.times_from_start[sub_splits[8]]).to be_within(50).of(4000)
      end
    end
  end

  describe '#time_from_start' do
    it 'predicts zero time for start splits' do
      effort = FactoryGirl.build_stubbed(:effort, id: 101)
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      sub_splits = ordered_splits.map(&:sub_splits).flatten
      working_split_time = split_times_101.first(5).last
      predictor = TimesPredictor.new(effort: effort,
                                     ordered_splits: ordered_splits,
                                     working_split_time: working_split_time,
                                     calc_model: :terrain)
      expect(predictor.time_from_start(sub_splits[0])).to eq(0)
    end

    it 'predicts the actual time from start for the specified working_sub_split' do
      effort = FactoryGirl.build_stubbed(:effort, id: 101)
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      working_split_time = split_times_101.first(5).last
      predictor = TimesPredictor.new(effort: effort,
                                     ordered_splits: ordered_splits,
                                     working_split_time: working_split_time,
                                     calc_model: :terrain)
      expect(predictor.time_from_start(working_split_time.sub_split)).to eq(2100)
    end

    it 'predicts the correct expected time from start for prior sub_splits using a calculated pace_factor' do
      effort = FactoryGirl.build_stubbed(:effort, id: 101)
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      sub_splits = ordered_splits.map(&:sub_splits).flatten
      working_split_time = split_times_101.first(5).last
      predictor = TimesPredictor.new(effort: effort,
                                     ordered_splits: ordered_splits,
                                     working_split_time: working_split_time,
                                     calc_model: :terrain)
      expect(predictor.time_from_start(sub_splits[1])).to be_within(50).of(1050)
      expect(predictor.time_from_start(sub_splits[2])).to be_within(50).of(1050)
      expect(predictor.time_from_start(sub_splits[3])).to be_within(50).of(2100)
    end

    it 'predicts the correct expected time from start for later sub_splits using a calculated pace_factor' do
      effort = FactoryGirl.build_stubbed(:effort, id: 101)
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      sub_splits = ordered_splits.map(&:sub_splits).flatten
      working_split_time = split_times_101.first(5).last
      predictor = TimesPredictor.new(effort: effort,
                                     ordered_splits: ordered_splits,
                                     working_split_time: working_split_time,
                                     calc_model: :terrain)
      expect(predictor.time_from_start(sub_splits[5])).to be_within(50).of(3150)
      expect(predictor.time_from_start(sub_splits[6])).to be_within(50).of(3150)
      expect(predictor.time_from_start(sub_splits[7])).to be_within(50).of(4200)
      expect(predictor.time_from_start(sub_splits[8])).to be_within(50).of(4200)
      expect(predictor.time_from_start(sub_splits[9])).to be_within(50).of(5250)
    end
  end

  describe '#segment_time' do
    it 'predicts the correct expected time for a given segment using a calculated pace factor' do
      skip
      effort = FactoryGirl.build_stubbed(:effort, id: 101)
      ordered_splits = [split1, split2, split3, split4, split5, split6]
      sub_splits = ordered_splits.map(&:sub_splits).flatten
      working_split_time = split_times_101.first(5).last
      # segment = Segment.new()
      predictor = TimesPredictor.new(effort: effort,
                                     ordered_splits: ordered_splits,
                                     working_split_time: working_split_time,
                                     calc_model: :terrain)
      expect(predictor.segment_time(segment1)).to be_within(50).of(3150)
      expect(predictor.time_from_start(sub_splits[6])).to be_within(50).of(3150)
      expect(predictor.time_from_start(sub_splits[7])).to be_within(50).of(4200)
      expect(predictor.time_from_start(sub_splits[8])).to be_within(50).of(4200)
      expect(predictor.time_from_start(sub_splits[9])).to be_within(50).of(5250)
    end
  end
end