require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe SegmentTimes do
  let(:split1) { FactoryGirl.build_stubbed(:split, course_id: 10, distance_from_start: 10000, vert_gain_from_start: 1000) }
  let(:split2) { FactoryGirl.build_stubbed(:split, course_id: 10, distance_from_start: 20000, vert_gain_from_start: 2000) }
  let(:split3) { FactoryGirl.build_stubbed(:split, course_id: 10, distance_from_start: 30000, vert_gain_from_start: 3000) }
  let(:sub_split1) { split1.sub_split_out }
  let(:sub_split2) { split2.sub_split_in }
  let(:sub_split3) { split3.sub_split_in }
  let(:sub_split4) { split3.sub_split_out }
  let(:segment1) { Segment.new(sub_split1, sub_split2, split1, split2) }
  let(:segment2) { Segment.new(sub_split3, sub_split4, split3, split3) }

  describe '#initialize' do
    let(:times_hash1) { {101 => 1000, 102 => 700, 103 => 1500} }
    let(:times_hash2) { {101 => 1100, 102 => 750, 103 => 1700} }

    it 'initializes with a valid segment and two time hashes' do
      segment_calcs = SegmentTimes.new(segment1, times_hash1, times_hash2)
      expect(segment_calcs.times.count).to eq(3)
    end
  end

  describe '#times' do
    it 'returns an empty hash if the time hashes are empty' do
      times_hash1 = {}
      times_hash2 = {}
      segment_calcs = SegmentTimes.new(segment1, times_hash1, times_hash2)
      expect(segment_calcs.times).to eq({})
    end

    context 'between splits' do
      it 'returns a hash with the difference in times for each effort' do
        times_hash1 = {101 => 1000, 102 => 700, 103 => 1500}
        times_hash2 = {101 => 1100, 102 => 750, 103 => 1700}
        segment_calcs = SegmentTimes.new(segment1, times_hash1, times_hash2)
        expect(segment_calcs.times).to eq({101 => 100, 102 => 50, 103 => 200})
      end

      it 'includes only those efforts reflected in both times hashes' do
        times_hash1 = {101 => 1000, 102 => 700, 103 => 1500, 104 => 2000}
        times_hash2 = {101 => 1100, 102 => 750, 103 => 1700, 105 => 2500}
        segment_calcs = SegmentTimes.new(segment1, times_hash1, times_hash2)
        expect(segment_calcs.times).to eq({101 => 100, 102 => 50, 103 => 200})
      end

      it 'ignores keys having nil values' do
        times_hash1 = {101 => 1000, 102 => 700, 103 => 1500, 104 => 2000, 105 => nil}
        times_hash2 = {101 => 1100, 102 => 750, 103 => 1700, 104 => nil, 105 => 2500}
        segment_calcs = SegmentTimes.new(segment1, times_hash1, times_hash2)
        expect(segment_calcs.times).to eq({101 => 100, 102 => 50, 103 => 200})
      end
    end

    context 'within a split' do
      it 'returns a hash with the difference in times for each effort' do
        times_hash1 = {101 => 1000, 102 => 700, 103 => 1500}
        times_hash2 = {101 => 1100, 102 => 750, 103 => 1700}
        segment_calcs = SegmentTimes.new(segment2, times_hash1, times_hash2)
        expect(segment_calcs.times).to eq({101 => 100, 102 => 50, 103 => 200})
      end

      it 'includes only those efforts reflected in both times hashes' do
        times_hash1 = {101 => 1000, 102 => 700, 103 => 1500, 104 => 2000}
        times_hash2 = {101 => 1100, 102 => 750, 103 => 1700, 105 => 2500}
        segment_calcs = SegmentTimes.new(segment2, times_hash1, times_hash2)
        expect(segment_calcs.times).to eq({101 => 100, 102 => 50, 103 => 200})
      end

      it 'ignores keys having nil values' do
        times_hash1 = {101 => 1000, 102 => 700, 103 => 1500, 104 => 2000, 105 => nil}
        times_hash2 = {101 => 1100, 102 => 750, 103 => 1700, 104 => nil, 105 => 2500}
        segment_calcs = SegmentTimes.new(segment2, times_hash1, times_hash2)
        expect(segment_calcs.times).to eq({101 => 100, 102 => 50, 103 => 200})
      end
    end
  end

  describe '#mean' do
    it 'returns nil if the number of times is below the STAT_CALC_THRESHOLD' do
      times_hash1 = {101 => 1000, 102 => 700, 103 => 1500}
      times_hash2 = {101 => 1100, 102 => 750, 103 => 1700}
      segment_calcs = SegmentTimes.new(segment1, times_hash1, times_hash2)
      expect(segment_calcs.mean).to be_nil
    end

    context 'between splits' do
      it 'returns the mean and standard deviation when the number of times is above the STAT_CALC_THRESHOLD' do
        times_hash1 = {101 => 10000, 102 => 7000, 103 => 15000, 104 => 20000, 105 => 21000,
                       106 => 30000, 107 => 31000, 108 => 40000, 109 => 41000, 110 => 50000}
        times_hash2 = {101 => 20000, 102 => 17000, 103 => 25000, 104 => 30000, 105 => 31000,
                       106 => 45000, 107 => 46000, 108 => 55000, 109 => 56000, 110 => 65000}
        segment_calcs = SegmentTimes.new(segment1, times_hash1, times_hash2)
        expect(segment_calcs.mean).to eq(12500)
      end
    end

    context 'within a split' do
      it 'returns the mean and standard deviation when the number of times is above the STAT_CALC_THRESHOLD' do
        times_hash1 = {101 => 10000, 102 => 7000, 103 => 15000, 104 => 20000, 105 => 21000,
                       106 => 30000, 107 => 31000, 108 => 40000, 109 => 41000, 110 => 50000}
        times_hash2 = {101 => 20000, 102 => 17000, 103 => 25000, 104 => 30000, 105 => 31000,
                       106 => 45000, 107 => 46000, 108 => 55000, 109 => 56000, 110 => 65000}
        segment_calcs = SegmentTimes.new(segment2, times_hash1, times_hash2)
        expect(segment_calcs.mean).to eq(12500)
      end
    end
  end

  describe '#status' do
    it 'returns "good", "bad", or "questionable" depending on where the provided time falls within the limits' do
      times_hash1 = {101 => 10000, 102 => 7000, 103 => 15000, 104 => 20000, 105 => 21000,
                     106 => 30000, 107 => 31000, 108 => 40000, 109 => 41000, 110 => 50000}
      times_hash2 = {101 => 20000, 102 => 17000, 103 => 25000, 104 => 30000, 105 => 31000,
                     106 => 45000, 107 => 46000, 108 => 55000, 109 => 56000, 110 => 65000}
      segment_calcs = SegmentTimes.new(segment1, times_hash1, times_hash2)
      expect(segment_calcs.status(2000)).to eq('bad')
      expect(segment_calcs.status(4000)).to eq('questionable')
      expect(segment_calcs.status(10000)).to eq('good')
      expect(segment_calcs.status(30000)).to eq('questionable')
      expect(segment_calcs.status(50000)).to eq('bad')
    end
  end

  describe '#estimated_time' do
    it 'returns #mean when available' do
      times_hash1 = {101 => 10000, 102 => 7000, 103 => 15000, 104 => 20000, 105 => 21000,
                     106 => 30000, 107 => 31000, 108 => 40000, 109 => 41000, 110 => 50000}
      times_hash2 = {101 => 20000, 102 => 17000, 103 => 25000, 104 => 30000, 105 => 31000,
                     106 => 45000, 107 => 46000, 108 => 55000, 109 => 56000, 110 => 65000}
      segment_calcs = SegmentTimes.new(segment1, times_hash1, times_hash2)
      expect(segment_calcs.estimated_time).to eq(12500)
    end

    it 'returns a terrain-based estimate when #mean is not available' do
      times_hash1 = {}
      times_hash2 = {}
      segment_calcs = SegmentTimes.new(segment1, times_hash1, times_hash2)
      expect(segment_calcs.estimated_time).to be_within(1000).of(10000)
    end
  end
end