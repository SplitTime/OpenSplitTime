# frozen_string_literal: true

require 'rails_helper'
include BitkeyDefinitions

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

  describe 'before_update' do
    subject { split_times(:sum_100k_drop_anvil_rolling_pass_aid2_out_1) }
    let(:proposed_time) { raw_times(:raw_time_87) }
    let(:proposed_time_id) { proposed_time.id }

    before { subject.matching_raw_time_id = proposed_time_id }

    shared_examples 'conforms and matches the proposed time' do
      it 'conforms the split_time with the raw_time' do
        expect(subject.military_time).not_to eq(proposed_time.military_time)
        subject.save
        expect(subject.military_time).to eq(proposed_time.military_time)
      end

      it 'matches the raw_time to the split_time' do
        expect(subject.raw_times).not_to include(proposed_time)

        subject.save
        subject.reload
        expect(subject.raw_times).to include(proposed_time)
      end
    end

    shared_examples 'does not conform or match the proposed time' do
      it 'does not change the split_time' do
        expect { subject.save }.not_to change { subject.military_time }
      end

      it 'does not match the raw_time to the split_time' do
        subject.save
        subject.reload
        expect(subject.raw_times).not_to include(proposed_time)
      end
    end

    context 'when matching_raw_time_id is set and exists' do
      include_examples 'conforms and matches the proposed time'
    end

    context 'when matching_raw_time_id is not found' do
      let(:proposed_time_id) { 0 }
      include_examples 'does not conform or match the proposed time'
    end

    context 'when matching_raw_time_id is nil' do
      let(:proposed_time_id) { nil }
      include_examples 'does not conform or match the proposed time'
    end

    context 'when the proposed time relates to another bib number in the same event group' do
      let(:proposed_time) { raw_times(:raw_time_76) }
      before { expect(proposed_time.bib_number.to_i).not_to eq(subject.bib_number) }
      before { expect(proposed_time.event_group_id).to eq(subject.event_group_id) }
      include_examples 'conforms and matches the proposed time'
    end

    context 'when the proposed time relates to another event group' do
      let(:proposed_time) { raw_times(:raw_time_50) }
      before { expect(proposed_time.event_group_id).not_to eq(subject.event_group_id) }
      include_examples 'does not conform or match the proposed time'
    end
  end

  describe "before_save" do
    context "for an existing split time" do
      subject { split_times(:hardrock_2016_brinda_fisher_telluride_out_1) }
      context "if elapsed seconds is not already set" do
        it "sets elapsed seconds based on absolute time" do
          expect(subject.elapsed_seconds).to be_nil

          subject.update!(absolute_time: "2016-07-15 22:00:00")
          subject.reload
          expect(subject.elapsed_seconds).to eq(10.hours)
        end
      end

      context "if elapsed seconds is already set" do
        before do
          subject.write_attribute(:elapsed_seconds, 11.hours)
          subject.save!
        end
        it "sets elapsed seconds based on absolute time" do
          expect(subject.elapsed_seconds).to eq(11.hours)

          subject.update!(absolute_time: "2016-07-15 22:00:00")
          subject.reload
          expect(subject.elapsed_seconds).to eq(10.hours)
        end
      end
    end

    context "for a newly created split time" do
      subject { build(:split_time, effort: effort, split: split, bitkey: in_bitkey, absolute_time: "2016-07-16 21:00:00") }
      let(:effort) { efforts(:hardrock_2016_brinda_fisher) }
      let(:split) { splits(:hardrock_cw_sherman) }
      it "sets elapsed seconds based on absolute time" do
        expect(subject.elapsed_seconds).to be_nil

        subject.save
        subject.reload
        expect(subject.elapsed_seconds).to eq(33.hours)
      end
    end

    context "for a starting split time" do
      subject { split_times(:hardrock_2016_brinda_fisher_start_1) }
      let(:effort) { subject.effort }
      let(:effort_split_times) { effort.ordered_split_times }
      it "sets elapsed seconds for all split times for the effort" do
        effort_split_times.each(&:reload)
        expect(effort_split_times.map(&:elapsed_seconds)).to all be_nil

        subject.update(absolute_time: "2016-07-15 11:00:00")

        effort_split_times.each(&:reload)
        expect(effort_split_times.map(&:elapsed_seconds)).to eq([0.0, 43020.0, 43200.0, 68160.0, 69900.0, 97500.0, 98340.0])

        subject.update(absolute_time: "2016-07-15 12:00:00")

        effort_split_times.each(&:reload)
        expect(effort_split_times.map(&:elapsed_seconds)).to eq([0.0, 39420.0, 39600.0, 64560.0, 66300.0, 93900.0, 94740.0])
      end
    end
  end

  describe "before destroy" do
    context "for a starting split time when later split times exist" do
      subject { split_times(:hardrock_2016_brinda_fisher_start_1) }
      let(:effort) { subject.effort }
      it "sets elapsed seconds for all effort split times to nil" do
        subject.update(absolute_time: "2016-07-15 11:00:00")

        effort.ordered_split_times.each(&:reload)
        expect(effort.ordered_split_times.map(&:elapsed_seconds)).to eq([0.0, 43020.0, 43200.0, 68160.0, 69900.0, 97500.0, 98340.0])

        subject.destroy

        effort.reload
        effort.ordered_split_times.each(&:reload)
        expect(effort.ordered_split_times.map(&:elapsed_seconds)).to all be_nil
      end
    end

    context "for a starting split time when no other split times exist" do
      subject { split_times(:hardrock_2016_start_only_start_1) }
      let(:effort) { subject.effort }
      it "behaves as expected" do
        subject.destroy

        effort.reload
        expect(effort.split_times.count).to eq(0)
      end
    end
  end

  describe 'virtual time attributes' do
    subject(:split_time) { effort.ordered_split_times.second }
    let(:effort) { efforts(:hardrock_2014_finished_first) }
    let(:event) { effort.event }
    let(:home_time_zone) { event.home_time_zone }
    let(:starting_split_time) { effort.starting_split_time }
    let(:effort_start_time) { starting_split_time.absolute_time }

    describe 'getters' do
      before { split_time.absolute_time = absolute_time }

      describe '#elapsed time' do

        context 'when absolute_time is nil' do
          let(:absolute_time) { nil }

          it 'returns nil' do
            expect(split_time.elapsed_time).to be_nil
          end
        end

        context 'when absolute_time is present' do
          let(:absolute_time) { effort_start_time + 4530 }

          it 'returns time in hh:mm:ss format' do
            expect(split_time.elapsed_time).to eq('01:15:30')
          end
        end

        context 'when time_from_start is less than one hour' do
          let(:absolute_time) { effort_start_time + 950 }

          it 'returns time in hh:mm:ss format ' do
            expect(split_time.elapsed_time).to eq('00:15:50')
          end
        end

        context 'when time_from_start is less than one minute' do
          let(:absolute_time) { effort_start_time + 45 }

          it 'returns time in hh:mm:ss format ' do
            expect(split_time.elapsed_time).to eq('00:00:45')
          end
        end

        context 'when time_from_start is greater than 24 hours' do
          let(:absolute_time) { effort_start_time + 100_000 }

          it 'returns time in hh:mm:ss format ' do
            expect(split_time.elapsed_time).to eq('27:46:40')
          end
        end

        context 'when time_from_start is greater than 100 hours' do
          let(:absolute_time) { effort_start_time + 500_000 }

          it 'returns time in hh:mm:ss format ' do
            expect(split_time.elapsed_time).to eq('138:53:20')
          end
        end

        context 'when with_fractionals: true is used' do
          let(:absolute_time) { effort_start_time + 4530.55 }
          let(:with_fractionals) { true }

          it 'returns time in hh:mm:ss.xx format' do
            expect(split_time.elapsed_time(with_fractionals: with_fractionals)).to eq('01:15:30.55')
          end
        end

        context 'when with_fractionals: true is used' do
          let(:absolute_time) { effort_start_time + 4530.55 }
          let(:with_fractionals) { false }

          it 'returns time in hh:mm:ss.xx format' do
            expect(split_time.elapsed_time(with_fractionals: with_fractionals)).to eq('01:15:31')
          end
        end
      end

      describe '#absolute_time_local' do
        before { split_time.absolute_time = absolute_time }

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

      describe '#military time' do
        context 'when absolute_time is nil' do
          let(:absolute_time) { nil }

          it 'returns nil' do
            expect(split_time.military_time).to be_nil
          end
        end

        context 'when absolute_time is present' do
          let(:absolute_time) { effort_start_time + 3600 }
          let(:expected_day_and_time) { absolute_time.in_time_zone(home_time_zone) }
          let(:expected_military_time) { expected_day_and_time.strftime('%H:%M:%S') }

          it 'returns military time in hh:mm:ss format' do
            expect(split_time.military_time).to eq(expected_military_time)
          end
        end
      end
    end

    describe 'setters' do
      describe '#elapsed_time=' do
        before { split_time.elapsed_time = time_arg }

        context 'when passed a nil value' do
          let(:time_arg) { nil }

          it 'removes an existing absolute_time' do
            expect(split_time).to be_absolute_time_changed
            expect(split_time.absolute_time).to be_nil
          end
        end

        context 'when passed an empty string' do
          let(:time_arg) { '' }

          it 'removes an existing absolute_time' do
            expect(split_time).to be_absolute_time_changed
            expect(split_time.absolute_time).to be_nil
          end
        end

        context 'when passed a string representing less than one minute' do
          let(:time_arg) { '00:00:25' }

          it 'sets absolute_time properly' do
            expect(split_time).to be_absolute_time_changed
            expect(split_time.absolute_time).to eq(effort_start_time + 25.seconds)
          end
        end

        context 'when passed a string representing less than one hour' do
          let(:time_arg) { '00:30:25' }

          it 'sets absolute_time properly' do
            expect(split_time).to be_absolute_time_changed
            expect(split_time.absolute_time).to eq(effort_start_time + 30.minutes + 25.seconds)
          end
        end

        context 'when passed a string representing more than one hour' do
          let(:time_arg) { '01:15:25' }

          it 'sets absolute_time properly' do
            expect(split_time).to be_absolute_time_changed
            expect(split_time.absolute_time).to eq(effort_start_time + 1.hour + 15.minutes + 25.seconds)
          end
        end

        context 'when passed a string representing more than 24 hours' do
          let(:time_arg) { '27:46:45' }

          it 'sets absolute_time properly' do
            expect(split_time).to be_absolute_time_changed
            expect(split_time.absolute_time).to eq(effort_start_time + 27.hours + 46.minutes + 45.seconds)
          end
        end

        context 'when passed a string representing more than 100 hours' do
          let(:time_arg) { '138:53:20' }

          it 'sets absolute_time properly' do
            expect(split_time).to be_absolute_time_changed
            expect(split_time.absolute_time).to eq(effort_start_time + 138.hours + 53.minutes + 20.seconds)
          end
        end

        context 'when no starting split time exists' do
          let(:effort) { efforts(:hardrock_2014_without_start) }
          let(:split_time) { effort.ordered_split_times.first }
          let(:time_arg) { '05:00:00' }

          it 'returns without modifying the absolute time' do
            expect(split_time).not_to be_absolute_time_changed
          end
        end

        context 'when the subject is a starting split time' do
          let(:split_time) { starting_split_time }
          let(:time_arg) { '05:00:00' }

          it 'returns without modifying the absolute time' do
            expect(split_time).not_to be_absolute_time_changed
          end
        end
      end

      describe '#absolute_time_local=' do
        before { split_time.absolute_time_local = time_arg }

        context 'when passed a nil value' do
          let(:time_arg) { nil }

          it 'sets absolute_time to nil' do
            expect(split_time.absolute_time).to be_nil
          end
        end

        context 'when passed an empty string' do
          let(:time_arg) { '' }

          it 'sets absolute_time to nil' do
            expect(split_time.absolute_time).to be_nil
          end
        end

        context 'when passed a datetime string' do
          let(:time_arg) { '2018-10-30 08:00:00' }

          it 'sets absolute_time to the UTC equivalent' do
            expect(split_time.absolute_time).to eq(time_arg.in_time_zone(home_time_zone))
          end
        end
      end

      describe '#military_time=' do
        let(:elapsed_seconds) { 1.hour }

        context 'for a split_time not affected by Daylight Savings' do
          before { split_time.military_time = time_arg }

          context 'when passed a nil value' do
            let(:time_arg) { nil }

            it 'sets absolute_time to nil' do
              expect(split_time.absolute_time).to be_nil
            end
          end

          context 'when passed an empty string' do
            let(:time_arg) { '' }

            it 'sets absolute_time to nil' do
              expect(split_time.absolute_time).to be_nil
            end
          end

          context 'when passed a military time string' do
            let(:time_arg) { '06:05:00' }

            it 'sets the time attribute properly' do
              expect(split_time.absolute_time_local).to eq('2014-07-11 06:05:00'.in_time_zone(home_time_zone))
            end
          end
        end

        context 'for a split_time occurring on the day that Daylight Savings Time switches' do
          let(:effort) { efforts(:sum_100k_on_dst_change) }
          let(:split_time) { effort.ordered_split_times.last }
          let(:time_arg) { '09:30:00' }

          before do
            effort.event.update(start_time_local: start_time_local)
            split_time.military_time = time_arg
          end

          context 'when the event starts on a day before the DST change' do
            let(:start_time_local) { '2017-09-23 07:00:00' }

            it 'sets time attributes correctly' do
              expect(split_time.military_time).to eq(time_arg)
            end
          end

          context 'when the event starts before the DST change on the day of the DST change' do
            let(:start_time_local) { '2017-11-05 01:00:00' }

            it 'sets absolute_time properly' do
              expect(split_time.military_time).to eq(time_arg)
            end
          end

          context 'when the event starts after the DST change' do
            let(:start_time_local) { '2017-11-05 07:00:00' }

            it 'sets absolute_time properly' do
              expect(split_time.military_time).to eq(time_arg)
            end
          end
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
