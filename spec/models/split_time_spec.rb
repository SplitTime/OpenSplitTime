require 'rails_helper'

# t.integer  "effort_id"
# t.integer  "split_id"
# t.float    "time_from_start" (stored as seconds.fractions of a second elapsed)
# t.integer  "data_status"
# t.integer  "sub_split_bitkey"
# t.boolean  "pacer"
# t.string   "remarks"

RSpec.describe SplitTime, kind: :model do
  it_behaves_like 'data_status_methods'
  it_behaves_like 'auditable'
  let(:in_bitkey) { SubSplit::IN_BITKEY }
  let(:out_bitkey) { SubSplit::OUT_BITKEY }

  describe 'validations' do
    context 'for validations that do not depend on existing records in the database' do
      subject(:split_time) { build_stubbed(:split_time, effort: effort, split: start_split, bitkey: in_bitkey, absolute_time: event.start_time) }
      let(:course) { build_stubbed(:course) }
      let(:start_split) { build_stubbed(:start_split, course: course) }
      let(:intermediate_split) { build_stubbed(:split, course: course) }
      let(:event) { build_stubbed(:event, course: course) }
      let(:effort) { build_stubbed(:effort, event: event) }

      it 'is valid when created with an effort, a split, a sub_split, a time_from_start, and a lap' do
        expect(split_time.effort).to be_present
        expect(split_time.split).to be_present
        expect(split_time.sub_split).to be_present
        expect(split_time.absolute_time).to be_present
        expect(split_time.lap).to be_present
        expect(split_time).to be_valid
      end

      context 'when no effort exists' do
        before { split_time.effort = nil }

        it 'is invalid' do
          expect(split_time).not_to be_valid
          expect(split_time.errors[:effort]).to include("can't be blank")
        end
      end

      context 'when no split exists' do
        before { split_time.split = nil }

        it 'is invalid' do
          expect(split_time).not_to be_valid
          expect(split_time.errors[:split]).to include("can't be blank")
        end
      end

      context 'when no sub_split_bitkey exists' do
        before { split_time.sub_split_bitkey = nil }

        it 'is invalid' do
          expect(split_time).not_to be_valid
          expect(split_time.errors[:sub_split_bitkey]).to include("can't be blank")
        end
      end

      context 'when no absolute_time exists' do
        before { split_time.absolute_time = nil }

        it 'is invalid' do
          expect(split_time).not_to be_valid
          expect(split_time.errors[:absolute_time]).to include("can't be blank")
        end
      end

      context 'when no lap exists' do
        before { split_time.lap = nil }

        it 'is invalid' do
          expect(split_time).not_to be_valid
          expect(split_time.errors[:lap]).to include("can't be blank")
        end
      end
    end

    context 'for validations that rely on existing records in the database' do
      let(:course) { create(:course) }
      let(:start_split) { create(:start_split, course: course) }
      let(:intermediate_split) { create(:split, course: course) }
      let(:event) { create(:event, course: course) }
      let(:effort) { build(:effort, event: event) }

      before { create(:split_time, effort: effort, lap: 1, split: intermediate_split, bitkey: in_bitkey, absolute_time: event.start_time + 1.hour) }

      context 'when more than one of a given time_point exists within an effort' do
        let(:split_time) { build_stubbed(:split_time, effort: effort, lap: 1, split: intermediate_split, bitkey: in_bitkey, absolute_time: event.start_time + 2.hours) }

        it 'is invalid' do
          expect(split_time).not_to be_valid
          expect(split_time.errors[:split_id]).to include('only one of any given time_point permitted within an effort')
        end
      end

      it 'allows within an effort one of a given split_id/lap combination for each sub_split' do
        build_stubbed(:split_time, effort: effort, split: intermediate_split, bitkey: in_bitkey, lap: 1)
        split_time = build_stubbed(:split_time, effort: effort, split: intermediate_split, bitkey: out_bitkey, lap: 1)
        expect(split_time).to be_valid
      end

      it 'allows multiple of a given split_id/sub_split/lap combination within different efforts' do
        efforts = build_stubbed_list(:effort, 3, event: event)
        build_stubbed(:split_time, effort: effort, split: intermediate_split, bitkey: in_bitkey, lap: 1)
        split_time_1 = build_stubbed(:split_time, effort: efforts.first, split: intermediate_split, bitkey: in_bitkey, lap: 1)
        split_time_2 = build_stubbed(:split_time, effort: efforts.second, split: intermediate_split, bitkey: in_bitkey, lap: 1)
        split_time_3 = build_stubbed(:split_time, effort: efforts.third, split: intermediate_split, bitkey: in_bitkey, lap: 1)
        expect(split_time_1).to be_valid
        expect(split_time_2).to be_valid
        expect(split_time_3).to be_valid
      end

      it 'ensures that effort.event.course_id is the same as split.course_id' do
        course_1 = build_stubbed(:course)
        course_2 = build_stubbed(:course)
        event = build_stubbed(:event, course: course_1)
        effort = build_stubbed(:effort, event: event)
        split = build_stubbed(:split, course: course_2)
        split_time = build(:split_time, effort: effort, split: split)
        expect(split_time).not_to be_valid
        expect(split_time.errors[:effort_id]).to include('the effort.event.course_id does not resolve with the split.course_id')
        expect(split_time.errors[:split_id]).to include('the effort.event.course_id does not resolve with the split.course_id')
      end
    end
  end

  describe '#elapsed time' do
    it 'returns nil when time_from_start is nil' do
      split_time = build_stubbed(:split_time, time_from_start: nil)
      expect(split_time.elapsed_time).to be_nil
    end

    it 'returns time in hh:mm:ss format when time_from_start is present' do
      split_time = build_stubbed(:split_time, time_from_start: 4530)
      expect(split_time.elapsed_time).to eq('01:15:30')
    end

    it 'returns time in hh:mm:ss format when time_from_start is less than one hour' do
      split_time = build_stubbed(:split_time, time_from_start: 950)
      expect(split_time.elapsed_time).to eq('00:15:50')
    end

    it 'returns time in hh:mm:ss format when time_from_start is less than one minute' do
      split_time = build_stubbed(:split_time, time_from_start: 45)
      expect(split_time.elapsed_time).to eq('00:00:45')
    end

    it 'returns time in hh:mm:ss format when time_from_start is greater than 24 hours' do
      split_time = build_stubbed(:split_time, time_from_start: 100000)
      expect(split_time.elapsed_time).to eq('27:46:40')
    end

    it 'returns time in hh:mm:ss format when time_from_start is greater than 100 hours' do
      split_time = build_stubbed(:split_time, time_from_start: 500000)
      expect(split_time.elapsed_time).to eq('138:53:20')
    end

    it 'returns time in hh:mm:ss.xx format when with_fractionals: true is used' do
      split_time = build_stubbed(:split_time, time_from_start: 4530.55)
      expect(split_time.elapsed_time(with_fractionals: true)).to eq('01:15:30.55')
    end

    it 'rounds fractional seconds when with_fractionals: is not true' do
      split_time = build_stubbed(:split_time, time_from_start: 4530.55)
      expect(split_time.elapsed_time).to eq('01:15:31')
    end
  end

  describe '#elapsed_time=' do
    it 'removes an existing time_from_start when passed a nil value' do
      split_time = build_stubbed(:split_time, time_from_start: 100000)
      split_time.elapsed_time = nil
      expect(split_time.time_from_start).to be_nil
    end

    it 'removes an existing time_from_start when passed an empty string' do
      split_time = build_stubbed(:split_time, time_from_start: 100000)
      split_time.elapsed_time = ''
      expect(split_time.time_from_start).to be_nil
    end

    it 'sets time_from_start properly when passed a string representing less than one minute' do
      split_time = build_stubbed(:split_time)
      split_time.elapsed_time = '00:00:25'
      expect(split_time.time_from_start).to eq(25)
    end

    it 'sets time_from_start properly when passed a string representing less than one hour' do
      split_time = build_stubbed(:split_time)
      split_time.elapsed_time = '00:30:25'
      expect(split_time.time_from_start).to eq(1825)
    end

    it 'sets time_from_start properly when passed a string representing more than one hour' do
      split_time = build_stubbed(:split_time)
      split_time.elapsed_time = '01:15:25'
      expect(split_time.time_from_start).to eq(4525)
    end

    it 'sets time_from_start properly when passed a string representing more than 24 hours' do
      split_time = build_stubbed(:split_time)
      split_time.elapsed_time = '27:46:45'
      expect(split_time.time_from_start).to eq(100005)
    end

    it 'sets time_from_start properly when passed a string representing more than 100 hours' do
      split_time = build_stubbed(:split_time)
      split_time.elapsed_time = '138:53:25'
      expect(split_time.time_from_start).to eq(500005)
    end
  end

  describe '#day_and_time' do
    let(:event) { build_stubbed(:event, start_time: Time.current) }

    context 'when start_offset is zero' do
      let(:effort) { build_stubbed(:effort, event: event, start_offset: 0) }

      it 'returns nil when time_from_start is nil' do
        split_time = build_stubbed(:split_time, time_from_start: nil)
        expect(split_time.day_and_time).to be_nil
      end

      it 'returns a day and time equal to event start_time if time_from_start and start_offset are zero' do
        split_time = build_stubbed(:split_time, effort: effort, time_from_start: 0)
        expect(split_time.day_and_time).to eq(effort.start_time)
      end

      it 'returns a day and time equal to event start_time plus time_from_start when start_offset is zero' do
        split_time = build_stubbed(:split_time, effort: effort, time_from_start: 1.hour)
        expect(split_time.day_and_time).to eq(effort.start_time + 1.hour)
      end

      it 'returns correct day and time when time_from_start is greater than 24 hours' do
        split_time = build_stubbed(:split_time, effort: effort, time_from_start: 27.hours)
        expect(split_time.day_and_time).to eq(effort.start_time + 27.hours)
      end

      it 'returns correct day and time when time_from_start is greater than 100 hours' do
        split_time = build_stubbed(:split_time, effort: effort, time_from_start: 127.hours)
        expect(split_time.day_and_time).to eq(effort.start_time + 127.hours)
      end
    end

    context 'when start_offset is greater than zero' do
      let(:effort) { build_stubbed(:effort, event: event, start_offset: 1.hour) }

      it 'returns correct day and time' do
        split_time = build_stubbed(:split_time, effort: effort, time_from_start: 2.hours)
        expect(split_time.day_and_time).to eq(event.start_time + 3.hours)
      end
    end

    context 'when start_offset is less than zero' do
      let(:effort) { build_stubbed(:effort, event: event, start_offset: -1.hour) }

      it 'returns correct day and time when start_offset is less than zero' do
        split_time = build_stubbed(:split_time, effort: effort, time_from_start: 2.hours)
        expect(split_time.day_and_time).to eq(event.start_time + 1.hour)
      end
    end
  end

  describe '#day_and_time=' do
    let(:event) { build_stubbed(:event, start_time: Time.current) }

    it 'sets time_from_start to nil if passed a nil value' do
      split_time = build_stubbed(:split_time, time_from_start: 1000)
      split_time.day_and_time = nil
      expect(split_time.time_from_start).to be_nil
    end

    context 'when the effort.start_offset is zero' do
      let(:effort) { build_stubbed(:effort, event: event, start_offset: 0) }

      it 'sets time_from_start to zero if passed the event start_time when start_offset is zero' do
        split_time = build_stubbed(:split_time, effort: effort)
        split_time.day_and_time = event.start_time
        expect(split_time.time_from_start).to eq(0)
      end

      it 'sets time_from_start properly if passed a TimeInZone object' do
        split_time = build_stubbed(:split_time, effort: effort)
        split_time.day_and_time = event.start_time + 9.hours
        expect(split_time.time_from_start).to eq(9.hours)
      end

      it 'sets time_from_start properly if passed a TimeInZone object that is more than 24 hours ahead' do
        split_time = build_stubbed(:split_time, effort: effort)
        split_time.day_and_time = event.start_time + 33.hours
        expect(split_time.time_from_start).to eq(33.hours)
      end

      it 'sets time_from_start properly if passed a TimeInZone object that is more than 100 hours ahead' do
        split_time = build_stubbed(:split_time, effort: effort)
        split_time.day_and_time = event.start_time + 105.hours
        expect(split_time.time_from_start).to eq(105.hours)
      end
    end

    context 'when the effort.start_offset is positive' do
      let(:effort) { build_stubbed(:effort, event: event, start_offset: 1.hour) }

      it 'sets time_from_start to zero if passed the event start_time plus the effort start offset' do
        split_time = build_stubbed(:split_time, effort: effort)
        split_time.day_and_time = event.start_time + 1.hour
        expect(split_time.time_from_start).to eq(0)
      end

      it 'sets time_from_start properly if passed a TimeInZone object' do
        split_time = build_stubbed(:split_time, effort: effort)
        split_time.day_and_time = event.start_time + 3.hours
        expect(split_time.time_from_start).to eq(2.hours)
      end
    end

    context 'when the effort.start_offset is negative' do
      let(:effort) { build_stubbed(:effort, event: event, start_offset: -1.hour) }

      it 'sets time_from_start properly if passed a TimeInZone object' do
        split_time = build_stubbed(:split_time, effort: effort)
        split_time.day_and_time = event.start_time + 3.hours
        expect(split_time.time_from_start).to eq(4.hours)
      end
    end
  end

  describe '#military time' do
    let(:event) { build_stubbed(:event, home_time_zone: 'Eastern Time (US & Canada)', start_time_in_home_zone: '2017-07-01 06:00:00') }

    it 'returns nil if time_from_start is nil' do
      split_time = build_stubbed(:split_time, time_from_start: nil)
      expect(split_time.military_time).to be_nil
    end

    context 'when effort.start_offset is zero' do
      let(:effort) { build_stubbed(:effort, event: event, start_offset: 0) }

      it 'returns military time in hh:mm:ss format when time_from_start is present' do
        split_time = build_stubbed(:split_time, effort: effort, time_from_start: 0)
        expect(split_time.military_time).to eq('06:00:00')
      end

      it 'returns military time in hh:mm:ss format when time_from_start does not roll into following day' do
        split_time = build_stubbed(:split_time, effort: effort, time_from_start: 1800)
        expect(split_time.military_time).to eq('06:30:00')
      end

      it 'returns military time in hh:mm:ss format when result is in the hour before midnight' do
        split_time = build_stubbed(:split_time, effort: effort, time_from_start: 64740)
        expect(split_time.military_time).to eq('23:59:00')
      end

      it 'returns military time in hh:mm:ss format when result is in the hour after midnight' do
        split_time = build_stubbed(:split_time, effort: effort, time_from_start: 64860)
        expect(split_time.military_time).to eq('00:01:00')
      end

      it 'returns military time in hh:mm:ss format when time_from_start rolls into following day' do
        split_time = build_stubbed(:split_time, effort: effort, time_from_start: 72000)
        expect(split_time.military_time).to eq('02:00:00')
      end

      it 'returns military time in hh:mm:ss format when time_from_start rolls over multiple days' do
        split_time = build_stubbed(:split_time, effort: effort, time_from_start: 302400)
        expect(split_time.military_time).to eq('18:00:00')
      end
    end

    context 'when effort.start_offset is positive' do
      let(:effort) { build_stubbed(:effort, event: event, start_offset: 30.minutes) }

      it 'properly accounts for a positive effort offset' do
        split_time = build_stubbed(:split_time, effort: effort, time_from_start: 30.minutes)
        expect(split_time.military_time).to eq('07:00:00')
      end
    end

    context 'when effort.start_offset is negative' do
      let(:effort) { build_stubbed(:effort, event: event, start_offset: -30.minutes) }

      it 'properly accounts for a negative effort offset' do
        split_time = build_stubbed(:split_time, effort: effort, time_from_start: 1.hour)
        expect(split_time.military_time).to eq('06:30:00')
      end
    end
  end

  describe '#military_time=' do
    let(:event) { build_stubbed(:event, home_time_zone: 'Eastern Time (US & Canada)', start_time_in_home_zone: '2017-07-01 06:00:00') }
    let(:effort) { build_stubbed(:effort, event: event, start_offset: 0) }

    it 'sets time_from_start to nil if passed a nil value' do
      split_time = build_stubbed(:split_time, effort: effort, time_from_start: 1000)
      split_time.military_time = nil
      expect(split_time.time_from_start).to be_nil
    end

    it 'sets time_from_start to nil if passed an empty string' do
      split_time = build_stubbed(:split_time, effort: effort, time_from_start: 1000)
      split_time.military_time = ''
      expect(split_time.time_from_start).to be_nil
    end

    it 'calls IntendedTimeCalculator with correct information if passed a present string' do
      lap = 1
      split_id = 101
      bitkey = in_bitkey
      time_point = TimePoint.new(lap, split_id, bitkey)
      military_time = '06:05:00'
      split_time = build_stubbed(:split_time, effort: effort, time_point: time_point)
      allow(split_time).to receive(:event_start_time).and_return(DateTime.parse('2017-07-01 06:00:00'))
      allow(IntendedTimeCalculator).to receive(:day_and_time).and_return(DateTime.parse('2017-07-01 08:00:00'))
      split_time.military_time = military_time
      expect(IntendedTimeCalculator).to have_received(:day_and_time).with(military_time: military_time,
                                                                          effort: effort,
                                                                          time_point: time_point)
    end
  end

  describe '#sub_split' do
    it 'returns split_id and sub_split_bitkey as a sub_split hash' do
      split_time = SplitTime.new(split_id: 101, bitkey: in_bitkey)
      expect(split_time.sub_split).to eq({101 => 1})
    end
  end

  describe '#sub_split=' do
    it 'sets both split_id and sub_split_bitkey' do
      split_time = SplitTime.new(sub_split: {101 => 1})
      expect(split_time.split_id).to eq(101)
      expect(split_time.bitkey).to eq(1)
    end
  end

  describe '#time_point' do
    it 'returns lap, split_id, and sub_split_bitkey in a TimePoint struct' do
      split_time = SplitTime.new(lap: 2, split_id: 101, bitkey: in_bitkey)
      expect(split_time.time_point).to eq(TimePoint.new(2, 101, 1))
    end
  end

  describe '#time_point=' do
    it 'sets lap, split_id, and sub_split_bitkey' do
      time_point = TimePoint.new(2, 101, 1)
      split_time = SplitTime.new(time_point: time_point)
      expect(split_time.split_id).to eq(101)
      expect(split_time.bitkey).to eq(1)
      expect(split_time.lap).to eq(2)
    end
  end

  describe '#lap_split' do
    it 'returns a LapSplit object' do
      lap = 2
      split_time = SplitTime.new(lap: lap, split_id: 101, bitkey: in_bitkey)
      split = Split.new(id: 101)
      allow(split_time).to receive(:split).and_return(split)
      expect(split_time.lap_split).to eq(LapSplit.new(lap, split))
    end
  end

  describe '#effort_lap_key' do
    it 'returns effort_id and lap in an EffortLapKey struct' do
      split_time = SplitTime.new(effort_id: 101, lap: 2)
      expect(split_time.effort_lap_key).to eq(EffortLapKey.new(101, 2))
    end
  end

  describe '#split_name' do
    it 'returns an "[unknown split]" indication if the split is not available' do
      st = SplitTime.new
      expected = '[unknown split]'
      expect(st.split_name).to eq(expected)
    end

    it 'does not indicate the lap even when available' do
      split = Split.new(base_name: 'Aid 1', sub_split_bitmap: 1)
      st = SplitTime.new(split: split, bitkey: in_bitkey, lap: 1)
      expected = 'Aid 1'
      expect(st.split_name).to eq(expected)
    end

    context 'for a split with multiple sub_splits' do
      it 'returns the name of the split with sub_split extension' do
        split = Split.new(base_name: 'Aid 1', sub_split_bitmap: 65)
        st = SplitTime.new(split: split, bitkey: in_bitkey)
        expected = 'Aid 1 In'
        expect(st.split_name).to eq(expected)

        st = SplitTime.new(split: split, bitkey: out_bitkey)
        expected = 'Aid 1 Out'
        expect(st.split_name).to eq(expected)
      end
    end

    context 'for a split with a single sub_split' do
      it 'returns the name of the split without any sub_split extension but with a lap indication' do
        split = Split.new(base_name: 'Aid 1', sub_split_bitmap: 1)
        st = SplitTime.new(split: split, bitkey: in_bitkey)
        expected = 'Aid 1'
        expect(st.split_name).to eq(expected)
      end
    end
  end

  describe '#split_name_with_lap' do
    it 'returns an "[unknown split]" indication if the split is not available' do
      st = SplitTime.new(lap: 1)
      expected = '[unknown split] Lap 1'
      expect(st.split_name_with_lap).to eq(expected)
    end

    it 'returns an "[unknown split] [unknown lap]" indication if neither lap nor split is available' do
      st = SplitTime.new
      expected = '[unknown split] [unknown lap]'
      expect(st.split_name_with_lap).to eq(expected)
    end

    context 'for a split with multiple sub_splits' do
      it 'returns the name of the split with sub_split extension and a lap indication' do
        split = Split.new(base_name: 'Aid 1', sub_split_bitmap: 65)
        st = SplitTime.new(split: split, bitkey: in_bitkey, lap: 1)
        expected = 'Aid 1 In Lap 1'
        expect(st.split_name_with_lap).to eq(expected)

        st = SplitTime.new(split: split, bitkey: out_bitkey, lap: 1)
        expected = 'Aid 1 Out Lap 1'
        expect(st.split_name_with_lap).to eq(expected)
      end

      it 'returns an "[unknown lap]" indication if the lap is not available' do
        split = Split.new(base_name: 'Aid 1', sub_split_bitmap: 65)
        st = SplitTime.new(split: split, bitkey: in_bitkey)
        expected = 'Aid 1 In [unknown lap]'
        expect(st.split_name_with_lap).to eq(expected)
      end
    end

    context 'for a split with a single sub_split' do
      it 'returns the name of the split without any sub_split extension but with a lap indication' do
        split = Split.new(base_name: 'Aid 1', sub_split_bitmap: 1)
        st = SplitTime.new(split: split, bitkey: in_bitkey, lap: 1)
        expected = 'Aid 1 Lap 1'
        expect(st.split_name_with_lap).to eq(expected)
      end

      it 'returns an "[unknown lap]" indication if the lap is not available' do
        split = Split.new(base_name: 'Aid 1', sub_split_bitmap: 1)
        st = SplitTime.new(split: split, bitkey: in_bitkey)
        expected = 'Aid 1 [unknown lap]'
        expect(st.split_name_with_lap).to eq(expected)
      end
    end
  end
end
