#frozen_string_literal: true

require 'rails_helper'
include BitkeyDefinitions

RSpec.describe FindExpectedLap do
  subject { FindExpectedLap.new(effort: effort, subject_attribute: subject_attribute, subject_value: subject_value, split_id: split_id, bitkey: bitkey) }
  let(:subject_attribute) { :military_time }

  let(:effort) { build_stubbed(:effort, split_times: split_times, event: event) }
  let(:split_id) { split.id }
  let(:bitkey) { in_bitkey }

  let(:event) { build_stubbed(:event, laps_required: 0, splits: splits, scheduled_start_time_local: '2018-06-22 06:00:00') }
  let(:start_time) { event.scheduled_start_time }
  let(:splits) { [start_split, aid_1_split, aid_2_split, finish_split] }
  let(:start_split) { build_stubbed(:split, :start, base_name: 'Start') }
  let(:aid_1_split) { build_stubbed(:split, base_name: 'Aid 1') }
  let(:aid_2_split) { build_stubbed(:split, base_name: 'Aid 2') }
  let(:finish_split) { build_stubbed(:split, :finish, base_name: 'Finish') }

  let(:split_time_1) { build_stubbed(:split_time, lap: 1, split: start_split, bitkey: 1, absolute_time: start_time + 0) }
  let(:split_time_2) { build_stubbed(:split_time, lap: 1, split: aid_1_split, bitkey: 1, absolute_time: start_time + 1.hour) }
  let(:split_time_3) { build_stubbed(:split_time, lap: 1, split: aid_1_split, bitkey: 64, absolute_time: start_time + 2.hours) }
  let(:split_time_4) { build_stubbed(:split_time, lap: 1, split: aid_2_split, bitkey: 1, absolute_time: start_time + 3.hours) }
  let(:split_time_5) { build_stubbed(:split_time, lap: 1, split: aid_2_split, bitkey: 64, absolute_time: start_time + 4.hours) }
  let(:split_time_6) { build_stubbed(:split_time, lap: 1, split: finish_split, bitkey: 1, absolute_time: start_time + 5.hours) }
  let(:split_time_7) { build_stubbed(:split_time, lap: 2, split: start_split, bitkey: 1, absolute_time: start_time + 6.hours) }
  let(:split_time_8) { build_stubbed(:split_time, lap: 2, split: aid_1_split, bitkey: 1, absolute_time: start_time + 7.hours) }
  let(:split_time_9) { build_stubbed(:split_time, lap: 2, split: aid_1_split, bitkey: 64, absolute_time: start_time + 8.hours) }
  let(:split_time_10) { build_stubbed(:split_time, lap: 2, split: aid_2_split, bitkey: 1, absolute_time: start_time + 9.hours) }
  let(:split_time_11) { build_stubbed(:split_time, lap: 2, split: aid_2_split, bitkey: 64, absolute_time: start_time + 10.hours) }
  let(:split_time_12) { build_stubbed(:split_time, lap: 2, split: finish_split, bitkey: 1, absolute_time: start_time + 11.hours) }
  let(:all_split_times) { [split_time_1, split_time_2, split_time_3, split_time_4, split_time_5, split_time_6,
                           split_time_7, split_time_8, split_time_9, split_time_10, split_time_11, split_time_12] }

  describe '#initialize' do
    let(:split_times) { [] }
    let(:subject_value) { '07:00:00' }
    let(:split) { start_split }

    it 'initializes with effort, subject_attribute, subject_value, split_id, and bitkey in an args hash' do
      expect { subject }.not_to raise_error
    end

    context 'if no effort is given' do
      let(:effort) { nil }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(/must include effort/)
      end
    end

    context 'if no subject_attribute is given' do
      let(:subject_attribute) { nil }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(/must include subject_attribute/)
      end
    end

    context 'if no subject_value is given' do
      let(:subject_value) { nil }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(/must include subject_value/)
      end
    end

    context 'if no split_id is given' do
      let(:split_id) { nil }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(/must include split_id/)
      end
    end

    context 'if no bitkey is given' do
      let(:bitkey) { nil }

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(/must include bitkey/)
      end
    end
  end

  describe '#perform' do
    before do
      FactoryBot.reload
      all_split_times.each { |st| st.assign_attributes(effort_id: effort.id) }
    end

    context 'when effort has no split_times' do
      let(:split_times) { [] }
      let(:subject_value) { '07:00:00' }
      let(:split) { start_split }

      it 'returns 1' do
        expect(subject.perform).to eq(1)
      end
    end

    context 'when split_times are present but none exist for the specified split' do
      let(:split) { aid_2_split }
      let(:subject_value) { '07:00:00' }
      let(:split_times) { all_split_times.first(3) } # Start and Aid 1 (in/out)

      it 'returns 1' do
        expect(subject.perform).to eq(1)
      end
    end

    context 'when the subject_value exactly matches an existing split_time at the same sub_split' do
      let(:split) { aid_1_split }
      let(:bitkey) { out_bitkey }
      let(:subject_value) { '08:00:00' }
      let(:split_times) { all_split_times.first(5) } # Start, Aid 1 (in/out), Aid 2 (in/out)

      it 'returns the lap of the matching split_time' do
        expect(subject.perform).to eq(1)
      end
    end

    context 'when split_times exist on lap 1 for the specified split' do
      let(:split) { aid_2_split }
      let(:subject_value) { '07:00:00' }
      let(:split_times) { all_split_times.first(5) } # Start, Aid 1 (in/out), Aid 2 (in/out)

      it 'returns 2' do
        expect(subject.perform).to eq(2)
      end
    end

    context 'when split_times exist on lap 2 but not on lap 1 for the specified split and time fills the hole' do
      let(:split) { aid_2_split }
      let(:subject_value) { '09:15:00' }
      let(:split_times) { all_split_times[0..2] + all_split_times[4..-1] } # Two complete laps except Aid 2 in

      it 'returns 1' do
        expect(subject.perform).to eq(1)
      end
    end

    context 'when split_times exist on lap 2 but not on lap 1 for the specified split and time does not fill the hole' do
      let(:split) { aid_2_split }
      let(:subject_value) { '10:15:00' }
      let(:split_times) { all_split_times[0..2] + all_split_times[4..-1] } # Two complete laps except Aid 2 in

      it 'returns 3' do
        expect(subject.perform).to eq(3)
      end
    end

    context 'when subject_attribute is absolute_time and specified split and time fills a hole' do
      let(:split) { aid_2_split }
      let(:subject_attribute) { :absolute_time }
      let(:subject_value) { ActiveSupport::TimeZone.new(event.home_time_zone).parse('2018-06-22 09:15:00') }
      let(:split_times) { all_split_times[0..2] + all_split_times[4..-1] } # Two complete laps except Aid 2 in

      it 'returns 1' do
        expect(subject.perform).to eq(1)
      end
    end

    context 'when subject_attribute is absolute_time and specified split and time does not fill a hole' do
      let(:split) { aid_2_split }
      let(:subject_attribute) { :absolute_time }
      let(:subject_value) { ActiveSupport::TimeZone.new(event.home_time_zone).parse('2018-06-22 10:15:00') }
      let(:split_times) { all_split_times[0..2] + all_split_times[4..-1] } # Two complete laps except Aid 2 in

      it 'returns 3' do
        expect(subject.perform).to eq(3)
      end
    end
  end
end
