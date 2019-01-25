# frozen_string_literal: true

require 'rails_helper'
include BitkeyDefinitions

# t.integer "effort_id", null: false
# t.integer "split_id", null: false
# t.integer "data_status"
# t.datetime "created_at", null: false
# t.datetime "updated_at", null: false
# t.integer "created_by"
# t.integer "updated_by"
# t.integer "sub_split_bitkey"
# t.boolean "pacer"
# t.string "remarks"
# t.integer "lap"
# t.boolean "stopped_here", default: false
# t.datetime "absolute_time"

RSpec.describe SplitTime, kind: :model do
  it_behaves_like 'data_status_methods'
  it_behaves_like 'auditable'
  it { is_expected.to localize_time_attribute(:absolute_time) }
  it { is_expected.to localize_time_attribute(:absolute_estimate_early) }
  it { is_expected.to localize_time_attribute(:absolute_estimate_late) }

  describe 'validations' do
    context 'for validations that do not depend on existing records in the database' do
      subject(:split_time) { build_stubbed(:split_time, effort: effort, split: start_split, bitkey: in_bitkey, absolute_time: event.start_time) }
      let(:course) { build_stubbed(:course) }
      let(:start_split) { build_stubbed(:split, :start, course: course) }
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
      let(:start_split) { create(:split, :start, course: course) }
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

  describe 'virtual time attributes' do
    subject(:split_time) { effort.ordered_split_times.second }
    let(:effort) { event.efforts.first }
    let(:event) { build_stubbed(:event_functional, efforts_count: 1) }
    let(:start_split_time) { effort.ordered_split_times.first }
    let(:effort_start_time) { event.start_time + start_offset }
    let(:start_offset) { 0 }
    let(:absolute_time) { effort_start_time + elapsed_seconds }
    let(:event_time_zone) { ActiveSupport::TimeZone.new(event.home_time_zone) }

    before do
      start_split_time.absolute_time = effort_start_time
      split_time.absolute_time = absolute_time
    end

    describe '#elapsed time' do
      context 'when absolute_time is nil' do
        let(:absolute_time) { nil }

        it 'returns nil' do
          expect(split_time.elapsed_time).to be_nil
        end
      end

      context 'when absolute_time is present' do
        let(:elapsed_seconds) { 4530 }

        it 'returns time in hh:mm:ss format' do
          expect(split_time.elapsed_time).to eq('01:15:30')
        end
      end

      context 'when time_from_start is less than one hour' do
        let(:elapsed_seconds) { 950 }

        it 'returns time in hh:mm:ss format ' do
          expect(split_time.elapsed_time).to eq('00:15:50')
        end
      end

      context 'when time_from_start is less than one minutea' do
        let(:elapsed_seconds) { 45 }

        it 'returns time in hh:mm:ss format ' do
          expect(split_time.elapsed_time).to eq('00:00:45')
        end
      end

      context 'when time_from_start is greater than 24 hours' do
        let(:elapsed_seconds) { 100_000 }

        it 'returns time in hh:mm:ss format ' do
          expect(split_time.elapsed_time).to eq('27:46:40')
        end
      end

      context 'when time_from_start is greater than 100 hours' do
        let(:elapsed_seconds) { 500_000 }

        it 'returns time in hh:mm:ss format ' do
          expect(split_time.elapsed_time).to eq('138:53:20')
        end
      end

      context 'when with_fractionals: true is used' do
        let(:elapsed_seconds) { 4530.55 }
        let(:with_fractionals) { true }

        it 'returns time in hh:mm:ss.xx format' do
          expect(split_time.elapsed_time(with_fractionals: with_fractionals)).to eq('01:15:30.55')
        end
      end

      context 'when with_fractionals: true is used' do
        let(:elapsed_seconds) { 4530.55 }
        let(:with_fractionals) { false }

        it 'returns time in hh:mm:ss.xx format' do
          expect(split_time.elapsed_time(with_fractionals: with_fractionals)).to eq('01:15:31')
        end
      end

      context 'when the start split_time is not the same as the event.start_time' do
        let(:elapsed_seconds) { 1.hour }
        let(:start_offset) { -2.hours }

        it 'returns time based on time elapsed from the start split_time' do
          expect(start_split_time.absolute_time).not_to eq(event.start_time)
          expect(split_time.elapsed_time).to eq('01:00:00')
        end
      end
    end

    describe '#elapsed_time=' do
      let(:elapsed_seconds) { 1.hour }

      context 'when passed a nil value' do
        it 'removes an existing absolute_time' do
          split_time.elapsed_time = nil
          expect(split_time.absolute_time).to be_nil
        end
      end

      context 'when passed an empty string' do
        it 'removes an existing absolute_time' do
          split_time.elapsed_time = ''
          expect(split_time.absolute_time).to be_nil
        end
      end

      context 'when passed a string representing less than one minute' do
        it 'sets absolute_time properly' do
          split_time.elapsed_time = '00:00:25'
          expect(split_time.absolute_time).to eq(effort_start_time + 25.seconds)
        end
      end

      context 'when passed a string representing less than one hour' do
        it 'sets absolute_time properly' do
          split_time.elapsed_time = '00:30:25'
          expect(split_time.absolute_time).to eq(effort_start_time + 30.minutes + 25.seconds)
        end
      end

      context 'when passed a string representing more than one hour' do
        it 'sets absolute_time properly' do
          split_time.elapsed_time = '01:15:25'
          expect(split_time.absolute_time).to eq(effort_start_time + 1.hour + 15.minutes + 25.seconds)
        end
      end

      context 'when passed a string representing more than 24 hours' do
        it 'sets absolute_time properly' do
          split_time.elapsed_time = '27:46:45'
          expect(split_time.absolute_time).to eq(effort_start_time + 27.hours + 46.minutes + 45.seconds)
        end
      end

      context 'when passed a string representing more than 100 hours' do
        it 'sets absolute_time properly' do
          split_time.elapsed_time = '138:53:20'
          expect(split_time.absolute_time).to eq(effort_start_time + 138.hours + 53.minutes + 20.seconds)
        end
      end

      context 'when the start split_time is not the same as the event.start_time' do
        let(:start_offset) { -2.hours }

        it 'sets absolute_time based on start split_time' do
          split_time.elapsed_time = '05:00:00'
          expect(split_time.absolute_time).to eq(effort_start_time + 5.hours)
        end
      end

      context 'when no starting split time exists' do
        before { start_split_time.absolute_time = nil }

        it 'returns without modifying the absolute time' do
          split_time.elapsed_time = '05:00:00'
          expect(split_time.absolute_time).to eq(effort_start_time + 1.hour)
        end
      end

      context 'when the subject is a starting split time' do
        it 'returns without modifying the absolute time' do
          start_split_time.elapsed_time = '05:00:00'
          expect(start_split_time.absolute_time).to eq(effort_start_time)
        end
      end
    end

    describe '#absolute_time_local' do
      context 'when absolute_time is nil' do
        let(:absolute_time) { nil }

        it 'returns nil' do
          expect(split_time.absolute_time_local).to be_nil
        end
      end

      context 'when absolute_time exists' do
        let(:absolute_time) { '2018-10-30 12:00:00' }

        it 'returns a day and time in the event home time zone' do
          expect(split_time.absolute_time_local).to eq(absolute_time)
          expect(split_time.absolute_time_local.time_zone).to eq(ActiveSupport::TimeZone.new(event.home_time_zone))
        end
      end
    end

    describe '#absolute_time_local=' do
      let(:elapsed_seconds) { 1.hour }

      context 'when passed a nil value' do
        it 'sets absolute_time to nil' do
          split_time.absolute_time_local = nil
          expect(split_time.absolute_time).to be_nil
        end
      end

      context 'when passed an empty string' do
        it 'sets absolute_time to nil' do
          split_time.absolute_time_local = ''
          expect(split_time.absolute_time).to be_nil
        end
      end

      context 'when passed a datetime string' do
        let(:local_datetime) { '2018-10-30 08:00:00' }

        it 'sets absolute_time to the UTC equivalent' do
          split_time.absolute_time_local = local_datetime
          expect(split_time.absolute_time).to eq(event_time_zone.parse(local_datetime))
        end
      end
    end

    describe '#military time' do
      let(:expected_day_and_time) { (effort_start_time + elapsed_seconds).in_time_zone(event_time_zone) }
      let(:expected_military_time) { expected_day_and_time.strftime('%H:%M:%S') }

      context 'when absolute_time is nil' do
        let(:absolute_time) { nil }

        it 'returns nil' do
          expect(split_time.military_time).to be_nil
        end
      end

      context 'when absolute_time is present' do
        let(:elapsed_seconds) { 3600 }

        it 'returns military time in hh:mm:ss format' do
          expect(split_time.military_time).to eq(expected_military_time)
        end
      end
    end

    describe '#military_time=' do
      let(:elapsed_seconds) { 1.hour }

      context 'when passed a nil value' do
        let(:military_time) { nil }

        it 'sets absolute_time to nil' do
          split_time.military_time = military_time
          expect(split_time.absolute_time).to be_nil
        end
      end

      context 'when passed an empty string' do
        let(:military_time) { '' }

        it 'sets absolute_time to nil' do
          split_time.military_time = military_time
          expect(split_time.absolute_time).to be_nil
        end
      end

      context 'when passed a military time string' do
        let(:military_time) { '06:05:00' }

        it 'calls IntendedTimeCalculator with correct information' do
          expect(IntendedTimeCalculator).to receive(:absolute_time_local).with(military_time: military_time,
                                                                               effort: effort,
                                                                               time_point: split_time.time_point)
          split_time.military_time = military_time
        end
      end
    end
  end

  describe '#sub_split' do
    it 'returns a SubSplit object with split_id and sub_split_bitkey' do
      split_time = SplitTime.new(split_id: 101, bitkey: in_bitkey)
      expect(split_time.sub_split).to eq(SubSplit.new(101, in_bitkey))
    end
  end

  describe '#sub_split=' do
    it 'sets both split_id and sub_split_bitkey' do
      split_time = SplitTime.new(sub_split: SubSplit.new(101, in_bitkey))
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
