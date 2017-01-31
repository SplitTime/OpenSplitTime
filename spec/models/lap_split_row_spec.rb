require 'rails_helper'
require 'pry-byebug'

RSpec.describe LapSplitRow, type: :model do
  let(:in_bitkey) { SubSplit::IN_BITKEY }
  let(:out_bitkey) { SubSplit::OUT_BITKEY }

  let(:course) { Course.new(name: 'Test Course 100') }
  let(:event) { Event.new(name: 'Test Event 2015', course: course, start_time: "2015-07-01 06:00:00", laps_required: 1) }
  let(:event_multi) { Event.new(name: 'Test Event 2015', course: course, start_time: "2015-07-01 06:00:00", laps_required: 2) }

  let(:effort_1) { Effort.new(event: event, bib_number: 1, city: 'Vancouver', state_code: 'BC', country_code: 'CA', age: 50, first_name: 'Jen', last_name: 'Huckster', gender: 'female') }
  let(:effort_2) { Effort.new(event: event, bib_number: 2, city: 'Boulder', state_code: 'CO', country_code: 'US', age: 23, first_name: 'Joe', last_name: 'Hardman', gender: 'male') }
  let(:effort_3) { Effort.new(event: event, bib_number: 3, start_offset: 3600, city: 'Denver', state_code: 'CO', country_code: 'US', age: 24, first_name: 'Mark', last_name: 'Runner', gender: 'male') }
  let(:effort_4) { Effort.new(event: event_multi, bib_number: 4, city: 'Denver', state_code: 'CO', country_code: 'US', age: 24, first_name: 'Mark', last_name: 'Runner', gender: 'male') }

  let(:split_1) { Split.new(course: course, base_name: 'Starting Line', distance_from_start: 0, sub_split_bitmap: 1, vert_gain_from_start: 0, vert_loss_from_start: 0, kind: 0) }
  let(:split_2) { Split.new(course: course, base_name: 'Aid Station 1', distance_from_start: 6000, sub_split_bitmap: 65, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2) }
  let(:split_3) { Split.new(course: course, base_name: 'Aid Station 2', distance_from_start: 15000, sub_split_bitmap: 73, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2) }
  let(:split_4) { Split.new(course: course, base_name: 'Finish Line', distance_from_start: 25000, sub_split_bitmap: 1, vert_gain_from_start: 700, vert_loss_from_start: 700, kind: 1) }

  let(:lap_1_split_1) { LapSplit.new(1, split_1) }
  let(:lap_1_split_2) { LapSplit.new(1, split_2) }
  let(:lap_1_split_3) { LapSplit.new(1, split_3) }
  let(:lap_1_split_4) { LapSplit.new(1, split_4) }
  let(:lap_2_split_1) { LapSplit.new(2, split_1) }
  let(:lap_2_split_2) { LapSplit.new(2, split_2) }
  let(:lap_2_split_3) { LapSplit.new(2, split_3) }
  let(:lap_2_split_4) { LapSplit.new(2, split_4) }

  let(:split_time_1) { SplitTime.new(effort: effort_1, lap: 1, split: split_1, bitkey: in_bitkey, time_from_start: 0, data_status: 2) }
  let(:split_time_2) { SplitTime.new(effort: effort_1, lap: 1, split: split_2, bitkey: in_bitkey, time_from_start: 4000, data_status: 2) }
  let(:split_time_3) { SplitTime.new(effort: effort_1, lap: 1, split: split_2, bitkey: out_bitkey, time_from_start: 4100, data_status: 2) }
  let(:split_time_4) { SplitTime.new(effort: effort_1, lap: 1, split: split_3, bitkey: in_bitkey, time_from_start: 15200, data_status: 2) }
  let(:split_time_6) { SplitTime.new(effort: effort_1, lap: 1, split: split_3, bitkey: out_bitkey, time_from_start: 15100, data_status: 0) }
  let(:split_time_7) { SplitTime.new(effort: effort_1, lap: 1, split: split_4, bitkey: in_bitkey, time_from_start: 21000, data_status: 2) }
  let(:split_time_8) { SplitTime.new(effort: effort_2, lap: 1, split: split_1, bitkey: in_bitkey, time_from_start: 0, data_status: 2) }
  let(:split_time_9) { SplitTime.new(effort: effort_2, lap: 1, split: split_2, bitkey: out_bitkey, time_from_start: 120, data_status: 0) }
  let(:split_time_10) { SplitTime.new(effort: effort_2, lap: 1, split: split_3, bitkey: in_bitkey, time_from_start: 24000, data_status: 2) }
  let(:split_time_12) { SplitTime.new(effort: effort_2, lap: 1, split: split_3, bitkey: out_bitkey, time_from_start: 150000, data_status: 0) }
  let(:split_time_13) { SplitTime.new(effort: effort_2, lap: 1, split: split_4, bitkey: in_bitkey, time_from_start: 40000, data_status: 1) }
  let(:split_time_14) { SplitTime.new(effort: effort_3, lap: 1, split: split_1, bitkey: in_bitkey, time_from_start: 0, data_status: 2) }
  let(:split_time_15) { SplitTime.new(effort: effort_3, lap: 1, split: split_2, bitkey: in_bitkey, time_from_start: 5000, data_status: 2) }
  let(:split_time_16) { SplitTime.new(effort: effort_3, lap: 1, split: split_2, bitkey: out_bitkey, time_from_start: 5000, data_status: 2) }
  let(:split_time_17) { SplitTime.new(effort: effort_3, lap: 1, split: split_3, bitkey: in_bitkey, time_from_start: 12200, data_status: 2) }
  let(:split_time_21) { SplitTime.new(effort: effort_1, lap: 2, split: split_1, bitkey: in_bitkey, time_from_start: 30000, data_status: 2) }
  let(:split_time_22) { SplitTime.new(effort: effort_1, lap: 2, split: split_2, bitkey: in_bitkey, time_from_start: 34000, data_status: 2) }
  let(:split_time_23) { SplitTime.new(effort: effort_1, lap: 2, split: split_2, bitkey: out_bitkey, time_from_start: 34100, data_status: 2) }
  let(:split_time_24) { SplitTime.new(effort: effort_1, lap: 2, split: split_3, bitkey: in_bitkey, time_from_start: 45200, data_status: 2) }
  let(:split_time_25) { SplitTime.new(effort: effort_1, lap: 2, split: split_3, bitkey: out_bitkey, time_from_start: 45200, data_status: 2) }
  let(:split_time_26) { SplitTime.new(effort: effort_1, lap: 2, split: split_4, bitkey: in_bitkey, time_from_start: 51000, data_status: 2) }

  let(:event_start_time) { event.start_time }
  let(:effort_1_start_time) { event_start_time + effort_1.start_offset }
  let(:effort_2_start_time) { event_start_time + effort_2.start_offset }
  let(:effort_3_start_time) { event_start_time + effort_3.start_offset }
  let(:effort_4_start_time) { event_start_time + effort_4.start_offset }

  let(:split_row_1) { LapSplitRow.new(lap_split: lap_1_split_1, split_times: [split_time_1], prior_time: nil, start_time: effort_1_start_time) }
  let(:split_row_2) { LapSplitRow.new(lap_split: lap_1_split_2, split_times: [split_time_2, split_time_3], prior_time: 0, start_time: effort_1_start_time) }
  let(:split_row_3) { LapSplitRow.new(lap_split: lap_1_split_3, split_times: [split_time_4, split_time_6], prior_time: 4100, start_time: effort_1_start_time) }
  let(:split_row_4) { LapSplitRow.new(lap_split: lap_1_split_4, split_times: [split_time_7], prior_time: 15100, start_time: effort_1_start_time) }
  let(:split_row_5) { LapSplitRow.new(lap_split: lap_1_split_1, split_times: [split_time_8], prior_time: nil, start_time: effort_2_start_time) }
  let(:split_row_6) { LapSplitRow.new(lap_split: lap_1_split_2, split_times: [nil, split_time_9], prior_time: 0, start_time: effort_2_start_time) }
  let(:split_row_7) { LapSplitRow.new(lap_split: lap_1_split_3, split_times: [split_time_10, split_time_12], prior_time: nil, start_time: effort_2_start_time) }
  let(:split_row_8) { LapSplitRow.new(lap_split: lap_1_split_4, split_times: [split_time_13], prior_time: 150000, start_time: effort_2_start_time) }
  let(:split_row_9) { LapSplitRow.new(lap_split: lap_1_split_1, split_times: [split_time_14], prior_time: nil, start_time: effort_3_start_time) }
  let(:split_row_10) { LapSplitRow.new(lap_split: lap_1_split_2, split_times: [split_time_15, split_time_16], prior_time: 0, start_time: effort_3_start_time) }
  let(:split_row_11) { LapSplitRow.new(lap_split: lap_1_split_3, split_times: [split_time_17, nil], prior_time: 5000, start_time: effort_3_start_time) }
  let(:split_row_12) { LapSplitRow.new(lap_split: lap_1_split_4, split_times: [nil, nil], prior_time: 12200, start_time: effort_3_start_time) }
  let(:split_row_21) { LapSplitRow.new(lap_split: lap_1_split_1, split_times: [split_time_21], prior_time: 12200, start_time: effort_4_start_time, show_laps: true) }
  let(:split_row_22) { LapSplitRow.new(lap_split: lap_1_split_2, split_times: [split_time_22, split_time_23], prior_time: 12200, start_time: effort_4_start_time, show_laps: true) }
  let(:split_row_23) { LapSplitRow.new(lap_split: lap_2_split_1, split_times: [split_time_21], prior_time: 12200, start_time: effort_4_start_time, show_laps: true) }
  let(:split_row_24) { LapSplitRow.new(lap_split: lap_2_split_2, split_times: [split_time_22, split_time_23], prior_time: 12200, start_time: effort_4_start_time, show_laps: true) }

  describe 'initialization' do
    it 'instantiates new objects properly' do
      expect(split_row_1.present?).to eq(true)
      expect(split_row_4.present?).to eq(true)
      expect(split_row_6.present?).to eq(true)
      expect(split_row_10.present?).to eq(true)
    end

    it 'instantiates a LapSplitRow even if no split_times are provided' do
      expect(split_row_12.present?).to eq(true)
    end
  end

  describe '#times_from_start' do
    it 'returns an array of times_from_start' do
      expect(split_row_1.times_from_start).to eq([0])
      expect(split_row_2.times_from_start).to eq([4000, 4100])
      expect(split_row_3.times_from_start).to eq([15200, 15100])
      expect(split_row_4.times_from_start).to eq([21000])
      expect(split_row_6.times_from_start).to eq([nil, 120])
      expect(split_row_11.times_from_start).to eq([12200, nil])
      expect(split_row_12.times_from_start).to eq([nil, nil])
    end
  end

  describe '#days_and_times' do
    it 'returns an array of datetime values based on event start_time and effort start_offset' do
      event_start_time = event.start_time
      effort_start_offset = effort_3.start_offset
      expect(split_row_1.days_and_times).to eq([event_start_time])
      expect(split_row_2.days_and_times).to eq([event_start_time + 4000, event_start_time + 4100])
      expect(split_row_4.days_and_times).to eq([event_start_time + 21000])
      expect(split_row_6.days_and_times).to eq([nil, event_start_time + 120])
      expect(split_row_9.days_and_times).to eq([event_start_time + effort_start_offset])
      expect(split_row_10.days_and_times).to eq([event_start_time + effort_start_offset + 5000, event_start_time + effort_start_offset + 5000])
      expect(split_row_11.days_and_times).to eq([event_start_time + effort_start_offset + 12200, nil])
      expect(split_row_12.days_and_times).to eq([nil, nil])
    end
  end

  describe '#time_data_statuses' do
    it 'returns an array of data statuses' do
      expect(split_row_1.time_data_statuses).to eq(['good'])
      expect(split_row_2.time_data_statuses).to eq(['good', 'good'])
      expect(split_row_3.time_data_statuses).to eq(['good', 'bad'])
      expect(split_row_4.time_data_statuses).to eq(['good'])
      expect(split_row_6.time_data_statuses).to eq([nil, 'bad'])
      expect(split_row_8.time_data_statuses).to eq(['questionable'])
      expect(split_row_11.time_data_statuses).to eq(['good', nil])
      expect(split_row_12.time_data_statuses).to eq([nil, nil])
    end
  end

  describe '#data_status' do
    it 'returns the worst of the time_data_statuses in the split_row_' do
      expect(split_row_1.data_status).to eq('good')
      expect(split_row_2.data_status).to eq('good')
      expect(split_row_3.data_status).to eq('bad')
      expect(split_row_4.data_status).to eq('good')
      expect(split_row_6.data_status).to eq('bad')
      expect(split_row_8.data_status).to eq('questionable')
      expect(split_row_11.data_status).to eq(nil)
      expect(split_row_12.data_status).to eq(nil)
    end
  end

  describe '#segment_time' do
    it 'returns nil when prior_time is nil' do
      expect(split_row_1.segment_time).to be_nil
      expect(split_row_5.segment_time).to be_nil
      expect(split_row_7.segment_time).to be_nil
      expect(split_row_9.segment_time).to be_nil
    end

    it 'returns nil when times_from_start contains only nil values' do
      expect(split_row_12.segment_time).to be_nil
    end

    it 'returns the correct segment_time when prior_time is provided and at least one time_from_start is available' do
      expect(split_row_2.segment_time).to eq(4000)
      expect(split_row_3.segment_time).to eq(11100)
      expect(split_row_4.segment_time).to eq(5900)
      expect(split_row_11.segment_time).to eq(7200)
    end
  end

  describe '#time_in_aid' do
    it 'returns nil when fewer than two split_times are provided' do
      expect(split_row_1.time_in_aid).to be_nil
      expect(split_row_4.time_in_aid).to be_nil
      expect(split_row_6.time_in_aid).to be_nil
      expect(split_row_11.time_in_aid).to be_nil
    end

    it 'returns the time difference between first and last split_times when two or more are provided' do
      expect(split_row_2.time_in_aid).to eq(100)
      expect(split_row_3.time_in_aid).to eq(-100)
      expect(split_row_7.time_in_aid).to eq(150000 - 24000)
    end
  end

  describe '#name' do
    it 'returns the split name if :show_laps is not provided' do
      expect(split_row_1.name).to eq('Starting Line')
    end

    it 'returns the split name with lap if show_laps: true' do
      expect(split_row_21.name).to eq('Starting Line Lap 1')
      expect(split_row_24.name).to eq('Aid Station 1 In / Out Lap 2')
    end
  end
end