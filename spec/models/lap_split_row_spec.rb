# frozen_string_literal: true

RSpec.describe LapSplitRow, type: :model do
  require 'support/bitkey_definitions'
  include BitkeyDefinitions

  subject(:lap_split_row) { LapSplitRow.new(lap_split: lap_split, split_times: split_times, show_laps: show_laps) }
  let(:show_laps) { false }

  let(:course) { Course.new(name: 'Test Course 100') }
  let(:event) { Event.new(course: course, event_group: event_group, start_time: '2015-07-01 06:00:00', laps_required: 1) }
  let(:event_group) { EventGroup.new(home_time_zone: 'Mountain Time (US & Canada)')}

  let(:effort) { Effort.new(event: event, bib_number: 1, city: 'Vancouver', state_code: 'BC', country_code: 'CA', age: 50, first_name: 'Jen', last_name: 'Huckster', gender: 'female') }

  let(:split_1) { Split.new(course: course, base_name: 'Starting Line', distance_from_start: 0, sub_split_bitmap: 1, vert_gain_from_start: 0, vert_loss_from_start: 0, kind: 0) }
  let(:split_2) { Split.new(course: course, base_name: 'Aid Station 1', distance_from_start: 6000, sub_split_bitmap: 65, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2) }
  let(:split_3) { Split.new(course: course, base_name: 'Aid Station 2', distance_from_start: 15000, sub_split_bitmap: 73, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2) }
  let(:split_4) { Split.new(course: course, base_name: 'Finish Line', distance_from_start: 25000, sub_split_bitmap: 1, vert_gain_from_start: 700, vert_loss_from_start: 700, kind: 1) }

  let(:lap_1_split_1) { LapSplit.new(1, split_1) }
  let(:lap_1_split_2) { LapSplit.new(1, split_2) }
  let(:lap_1_split_3) { LapSplit.new(1, split_3) }
  let(:lap_1_split_4) { LapSplit.new(1, split_4) }
  let(:lap_2_split_2) { LapSplit.new(2, split_2) }
  
  let(:tfs_1) { 0 }
  let(:tfs_2) { 4000 }
  let(:tfs_3) { 4100 }
  let(:tfs_4) { 15_200 }
  let(:tfs_5) { 15_100 }
  let(:tfs_6) { 21_000 }

  let(:split_time_data_blank) { SplitTimeData.new }
  let(:split_time_data_1) { SplitTimeData.new(effort_id: effort.id, lap: 1, split_id: split_1.id, bitkey: in_bitkey, time_from_start: tfs_1, segment_time: nil,
                                              absolute_time_string: (event_start_time + tfs_1).to_s, absolute_time_local_string: (event.start_time_local + tfs_1).to_s,
                                              data_status_numeric: 2) }
  let(:split_time_data_2) { SplitTimeData.new(effort_id: effort.id, lap: 1, split_id: split_2.id, bitkey: in_bitkey, time_from_start: tfs_2, segment_time: tfs_2 - tfs_1,
                                              absolute_time_string: (event_start_time + tfs_2).to_s, absolute_time_local_string: (event.start_time_local + tfs_2).to_s,
                                              data_status_numeric: 2) }
  let(:split_time_data_3) { SplitTimeData.new(effort_id: effort.id, lap: 1, split_id: split_2.id, bitkey: out_bitkey, time_from_start: tfs_3, segment_time: tfs_3 - tfs_2,
                                              absolute_time_string: (event_start_time + tfs_3).to_s, absolute_time_local_string: (event.start_time_local + tfs_3).to_s,
                                              data_status_numeric: 2) }
  let(:split_time_data_4) { SplitTimeData.new(effort_id: effort.id, lap: 1, split_id: split_3.id, bitkey: in_bitkey, time_from_start: tfs_4, segment_time: tfs_4 - tfs_3,
                                              absolute_time_string: (event_start_time + tfs_4).to_s, absolute_time_local_string: (event.start_time_local + tfs_4).to_s,
                                              data_status_numeric: 2) }
  let(:split_time_data_5) { SplitTimeData.new(effort_id: effort.id, lap: 1, split_id: split_3.id, bitkey: out_bitkey, time_from_start: tfs_5, segment_time: tfs_5 - tfs_4,
                                              absolute_time_string: (event_start_time + tfs_5).to_s, absolute_time_local_string: (event.start_time_local + tfs_5).to_s,
                                              data_status_numeric: 0) }
  let(:split_time_data_6) { SplitTimeData.new(effort_id: effort.id, lap: 1, split_id: split_4.id, bitkey: in_bitkey, time_from_start: tfs_6, segment_time: tfs_6 - tfs_5,
                                              absolute_time_string: (event_start_time + tfs_6).to_s, absolute_time_local_string: (event.start_time_local + tfs_6).to_s,
                                              data_status_numeric: 2) }

  let(:event_start_time) { event.start_time }

  describe '#initialize' do
    context 'when initialized with a lap_split and valid split_times for a split with in and out sub_splits' do
      let(:lap_split) { lap_1_split_2 }
      let(:split_times) { [split_time_data_2, split_time_data_3] }

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when initialized with a lap_split and valid split_time_data objects for a split with in and out sub_splits' do
      let(:lap_split) { lap_1_split_2 }
      let(:split_times) { [split_time_data_2, split_time_data_3] }

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when initialized with a lap_split and a single split_time for a split with only an in sub_split' do
      let(:lap_split) { lap_1_split_1 }
      let(:split_times) { [split_time_data_1] }

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when initialized with a lap_split and a single split_time for a split with in and out sub_splits' do
      let(:lap_split) { lap_1_split_2 }
      let(:split_times) { [split_time_data_2] }

      it 'raises an error' do
        expect { subject }.to raise_error ArgumentError, (/split_time objects must be provided for each sub_split/)
      end
    end

    context 'when initialized with a lap_split and an empty split_time array' do
      let(:lap_split) { lap_1_split_1 }
      let(:split_times) { [] }

      it 'raises an error' do
        expect { subject }.to raise_error ArgumentError, (/split_time objects must be provided for each sub_split/)
      end
    end

    context 'when initialized without a lap_split' do
      let(:lap_split) { nil }
      let(:split_times) { [split_time_data_2, split_time_data_3] }

      it 'raises an error' do
        expect { subject }.to raise_error ArgumentError, (/must include lap_split/)
      end
    end

    context 'when initialized without split_times' do
      let(:lap_split) { lap_1_split_1 }
      let(:split_times) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error ArgumentError, (/must include split_times/)
      end
    end
  end

  describe '#times_from_start' do
    context 'when provided with two valid split_time_data objects' do
      let(:lap_split) { lap_1_split_2 }
      let(:split_times) { [split_time_data_2, split_time_data_3] }

      it 'returns an array of times_from_start' do
        expect(subject.times_from_start).to eq([tfs_2, tfs_3])
      end
    end

    context 'when provided with on valid split_time_data object' do
      let(:lap_split) { lap_1_split_4 }
      let(:split_times) { [split_time_data_6] }

      it 'returns an array of a single time_from_start' do
        expect(subject.times_from_start).to eq([tfs_6])
      end
    end

    context 'when provided with one valid split_time_data object and one blank split_time_data object' do
      let(:lap_split) { lap_1_split_2 }
      let(:split_times) { [split_time_data_2, split_time_data_blank] }

      it 'returns an array of one seconds from start and a nil' do
        expect(subject.times_from_start).to eq([tfs_2, nil])
      end
    end
  end

  describe '#absolute_times_local' do
    context 'when provided with two valid split_time_data objects' do
      let(:lap_split) { lap_1_split_2 }
      let(:split_times) { [split_time_data_2, split_time_data_3] }

      it 'returns an array of datetime objects' do
        expect(subject.absolute_times_local).to all be_a(DateTime)
        expect(subject.absolute_times_local.map(&:to_s)).to eq(%w(2015-07-01T01:06:40-06:00 2015-07-01T01:08:20-06:00))
      end
    end

    context 'when provided with one valid split_time_data object and one blank split_time_data object' do
      let(:lap_split) { lap_1_split_2 }
      let(:split_times) { [split_time_data_2, split_time_data_blank] }

      it 'returns a datetime object and a nil' do
        expect(subject.absolute_times_local.map(&:class)).to eq([DateTime, NilClass])
        expect(subject.absolute_times_local.map(&:to_s)).to eq(['2015-07-01T01:06:40-06:00', ''])
      end
    end
  end

  describe '#time_data_statuses' do
    context 'when provided with two valid split_time_data objects' do
      let(:lap_split) { lap_1_split_3 }
      let(:split_times) { [split_time_data_4, split_time_data_5] }

      it 'returns an array of data statuses in word format' do
        expect(subject.time_data_statuses).to eq(%w(good bad))
      end
    end

    context 'when provided with one valid split_time_data object and one blank split_time_data object' do
      let(:lap_split) { lap_1_split_3 }
      let(:split_times) { [split_time_data_4, split_time_data_blank] }

      it 'returns an array of data statuses in word format' do
        expect(subject.time_data_statuses).to eq(['good', nil])
      end
    end
  end

  describe '#data_status' do
    context 'when provided with two good objects' do
      let(:lap_split) { lap_1_split_2 }
      let(:split_times) { [split_time_data_2, split_time_data_3] }

      it 'returns good' do
        expect(subject.data_status).to eq('good')
      end
    end

    context 'when provided with one good and one bad object' do
      let(:lap_split) { lap_1_split_3 }
      let(:split_times) { [split_time_data_4, split_time_data_5] }

      it 'returns bad' do
        expect(subject.data_status).to eq('bad')
      end
    end

    context 'when provided with one good and one nil object' do
      let(:lap_split) { lap_1_split_3 }
      let(:split_times) { [split_time_data_4, split_time_data_blank] }

      it 'returns nil' do
        expect(subject.data_status).to eq(nil)
      end
    end

    context 'when provided with one bad and one nil object' do
      let(:lap_split) { lap_1_split_3 }
      let(:split_times) { [split_time_data_blank, split_time_data_5] }

      it 'returns bad' do
        expect(subject.data_status).to eq('bad')
      end
    end

    context 'when provided with two nil objects' do
      let(:lap_split) { lap_1_split_3 }
      let(:split_times) { [split_time_data_blank, split_time_data_blank] }

      it 'returns nil' do
        expect(subject.data_status).to eq(nil)
      end
    end
  end

  describe '#segment_time' do
    context 'when provided with two populated split_times_data objects' do
      let(:lap_split) { lap_1_split_2 }
      let(:split_times) { [split_time_data_2, split_time_data_3] }

      it 'returns the segment_time of the first object' do
        expect(subject.segment_time).to eq(split_times.first.segment_time)
      end
    end

    context 'when provided with one populated split_times_data object followed by a blank object' do
      let(:lap_split) { lap_1_split_2 }
      let(:split_times) { [split_time_data_2, split_time_data_blank] }

      it 'returns the segment_time of the first object' do
        expect(subject.segment_time).to eq(split_times.first.segment_time)
      end
    end

    context 'when provided with one blank split_times_data object followed by a populated object' do
      let(:lap_split) { lap_1_split_2 }
      let(:split_times) { [split_time_data_blank, split_time_data_3] }

      it 'returns the segment_time of the second object' do
        expect(subject.segment_time).to eq(split_times.second.segment_time)
      end
    end

    context 'when provided with two blank split_times_data objects' do
      let(:lap_split) { lap_1_split_2 }
      let(:split_times) { [split_time_data_blank, split_time_data_blank] }

      it 'returns nil' do
        expect(subject.segment_time).to eq(nil)
      end
    end

    context 'when provided with a single split_times_data object' do
      let(:lap_split) { lap_1_split_4 }
      let(:split_times) { [split_time_data_6] }

      it 'returns the segment_time of the object' do
        expect(subject.segment_time).to eq(split_time_data_6.segment_time)
      end
    end
  end

  describe '#time_in_aid' do
    context 'when provided with two populated split_times_data objects' do
      let(:lap_split) { lap_1_split_2 }
      let(:split_times) { [split_time_data_2, split_time_data_3] }

      it 'returns the time_in_aid of the second object' do
        expect(subject.time_in_aid).to eq(split_times.second.segment_time)
      end
    end

    context 'when provided with one populated split_times_data object followed by a blank object' do
      let(:lap_split) { lap_1_split_2 }
      let(:split_times) { [split_time_data_2, split_time_data_blank] }

      it 'returns nil' do
        expect(subject.time_in_aid).to eq(nil)
      end
    end

    context 'when provided with one blank split_times_data object followed by a populated object' do
      let(:lap_split) { lap_1_split_2 }
      let(:split_times) { [split_time_data_blank, split_time_data_3] }

      it 'returns nil' do
        expect(subject.time_in_aid).to eq(nil)
      end
    end

    context 'when provided with two blank split_times_data objects' do
      let(:lap_split) { lap_1_split_2 }
      let(:split_times) { [split_time_data_blank, split_time_data_blank] }

      it 'returns nil' do
        expect(subject.time_in_aid).to eq(nil)
      end
    end

    context 'when provided with a single split_times_data object' do
      let(:lap_split) { lap_1_split_4 }
      let(:split_times) { [split_time_data_6] }

      it 'returns nil' do
        expect(subject.time_in_aid).to eq(nil)
      end
    end
  end

  describe '#name' do
    let(:lap_split) { lap_2_split_2 }
    let(:split_times) { [split_time_data_2, split_time_data_3] }

    context 'if :show_laps is not provided' do
      let(:show_laps) { false }

      it 'returns the split name' do
        expect(subject.name).to eq('Aid Station 1 In / Out')
      end
    end

    context 'if :show_laps is provided' do
      let(:show_laps) { true }

      it 'returns the split name with lap' do
        expect(subject.name).to eq('Aid Station 1 In / Out Lap 2')
      end
    end
  end
end
