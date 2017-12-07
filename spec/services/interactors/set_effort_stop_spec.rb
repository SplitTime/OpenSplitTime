require 'rails_helper'

RSpec.describe Interactors::SetEffortStop do
  subject { Interactors::SetEffortStop.new(effort, stop_status: stop_status, split_time: split_time) }
  let(:stop_status) { nil }
  let(:split_time) { nil }

  let(:split_times) { [split_time_1, split_time_2, split_time_3, split_time_4, split_time_5] }
  let(:in_bitkey) { SubSplit::IN_BITKEY }
  let(:out_bitkey) { SubSplit::OUT_BITKEY }

  let(:effort) { build_stubbed(:effort, event: event) }
  let(:event) { build_stubbed(:event, course: course) }
  let(:course) { build_stubbed(:course) }
  let(:split_1) { build_stubbed(:start_split, course: course) }
  let(:split_2) { build_stubbed(:split, course: course) }
  let(:split_3) { build_stubbed(:split, course: course) }
  let(:split_4) { build_stubbed(:finish_split, course: course) }

  describe '#initialize' do
    context 'when an effort is provided' do
      it 'initializes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when no effort is provided' do
      let(:effort) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error(/arguments must include a subject/)
      end
    end
  end

  describe '#perform' do
    before { allow(effort).to receive(:split_times).and_return(split_times) }

    context 'when no split_time has a stopped_here flag set to true' do
      let(:split_time_1) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_1, bitkey: in_bitkey, time_from_start: 0, stopped_here: false) }
      let(:split_time_2) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_2, bitkey: in_bitkey, time_from_start: 10000, stopped_here: false) }
      let(:split_time_3) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_2, bitkey: out_bitkey, time_from_start: 11000, stopped_here: false) }
      let(:split_time_4) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_3, bitkey: in_bitkey, time_from_start: 20000, stopped_here: false) }
      let(:split_time_5) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_3, bitkey: out_bitkey, time_from_start: 20000, stopped_here: false) }

      it 'sets the last split_time.stopped_here to true and all other split_times stopped_here to false' do
        response = subject.perform
        changed_split_times = [split_time_5]
        validate_response(response, changed_split_times)
        validate_stops(split_time_5)
      end
    end

    context 'when the final split_time has a stopped_here flag set to true' do
      let(:split_time_1) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_1, bitkey: in_bitkey, time_from_start: 0, stopped_here: false) }
      let(:split_time_2) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_2, bitkey: in_bitkey, time_from_start: 10000, stopped_here: false) }
      let(:split_time_3) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_2, bitkey: out_bitkey, time_from_start: 11000, stopped_here: false) }
      let(:split_time_4) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_3, bitkey: in_bitkey, time_from_start: 20000, stopped_here: false) }
      let(:split_time_5) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_3, bitkey: out_bitkey, time_from_start: 20000, stopped_here: true) }

      it 'sets the last split_time.stopped_here to true and all other split_times stopped_here to false' do
        response = subject.perform
        changed_split_times = []
        validate_response(response, changed_split_times)
        validate_stops(split_time_5)
      end
    end

    context 'when a split_time other than the final split_time has a stopped_here flag set to true' do
      let(:split_time_1) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_1, bitkey: in_bitkey, time_from_start: 0, stopped_here: false) }
      let(:split_time_2) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_2, bitkey: in_bitkey, time_from_start: 10000, stopped_here: false) }
      let(:split_time_3) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_2, bitkey: out_bitkey, time_from_start: 11000, stopped_here: false) }
      let(:split_time_4) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_3, bitkey: in_bitkey, time_from_start: 20000, stopped_here: true) }
      let(:split_time_5) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_3, bitkey: out_bitkey, time_from_start: 20000, stopped_here: false) }

      it 'sets the last split_time.stopped_here to true and all other split_times stopped_here to false' do
        response = subject.perform
        changed_split_times = [split_time_4, split_time_5]
        validate_response(response, changed_split_times)
        validate_stops(split_time_5)
      end
    end

    context 'when multiple split_times have a stopped_here flag set to true' do
      let(:split_time_1) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_1, bitkey: in_bitkey, time_from_start: 0, stopped_here: false) }
      let(:split_time_2) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_2, bitkey: in_bitkey, time_from_start: 10000, stopped_here: false) }
      let(:split_time_3) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_2, bitkey: out_bitkey, time_from_start: 11000, stopped_here: true) }
      let(:split_time_4) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_3, bitkey: in_bitkey, time_from_start: 20000, stopped_here: true) }
      let(:split_time_5) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_3, bitkey: out_bitkey, time_from_start: 20000, stopped_here: true) }

      it 'sets the last split_time.stopped_here to true and all other split_times stopped_here to false' do
        response = subject.perform
        changed_split_times = [split_time_3, split_time_4]
        validate_response(response, changed_split_times)
        validate_stops(split_time_5)
      end
    end

    context 'when a split_time is provided' do
      let(:split_time_1) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_1, bitkey: in_bitkey, time_from_start: 0, stopped_here: false) }
      let(:split_time_2) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_2, bitkey: in_bitkey, time_from_start: 10000, stopped_here: false) }
      let(:split_time_3) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_2, bitkey: out_bitkey, time_from_start: 11000, stopped_here: false) }
      let(:split_time_4) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_3, bitkey: in_bitkey, time_from_start: 20000, stopped_here: true) }
      let(:split_time_5) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_3, bitkey: out_bitkey, time_from_start: 20000, stopped_here: true) }
      let(:split_time) { split_time_3 }

      it 'sets the provided split_time.stopped_here to true and all other split_times stopped_here to false' do
        response = subject.perform
        changed_split_times = [split_time_3, split_time_4, split_time_5]
        validate_response(response, changed_split_times)
        validate_stops(split_time_3)
      end
    end

    context 'for a multi-lap event where stop_status is true' do
      let(:event) { build_stubbed(:event, course: course, laps_required: 2) }

      let(:split_time_1) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_1, bitkey: in_bitkey, time_from_start: 0, stopped_here: false) }
      let(:split_time_2) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_2, bitkey: in_bitkey, time_from_start: 10000, stopped_here: false) }
      let(:split_time_3) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_2, bitkey: out_bitkey, time_from_start: 11000, stopped_here: false) }
      let(:split_time_4) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_3, bitkey: in_bitkey, time_from_start: 20000, stopped_here: true) }
      let(:split_time_5) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_3, bitkey: out_bitkey, time_from_start: 20000, stopped_here: false) }
      let(:split_time_6) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_4, bitkey: in_bitkey, time_from_start: 30000, stopped_here: false) }
      let(:split_time_7) { build_stubbed(:split_time, effort: effort, lap: 2, split: split_1, bitkey: in_bitkey, time_from_start: 31000, stopped_here: false) }
      let(:split_times) { [split_time_1, split_time_2, split_time_3, split_time_4, split_time_5, split_time_6, split_time_7] }

      it 'sets the last split_time.stopped_here to true and all other split_times stopped_here to false' do
        response = subject.perform
        changed_split_times = [split_time_4, split_time_7]
        validate_response(response, changed_split_times)
        validate_stops(split_time_7)
      end
    end

    context 'when no split_time has a stopped_here flag set to true, and stop_status is false' do
      let(:split_time_1) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_1, bitkey: in_bitkey, time_from_start: 0, stopped_here: false) }
      let(:split_time_2) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_2, bitkey: in_bitkey, time_from_start: 10000, stopped_here: false) }
      let(:split_time_3) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_2, bitkey: out_bitkey, time_from_start: 11000, stopped_here: false) }
      let(:split_time_4) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_3, bitkey: in_bitkey, time_from_start: 20000, stopped_here: false) }
      let(:split_time_5) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_3, bitkey: out_bitkey, time_from_start: 20000, stopped_here: false) }
      let(:stop_status) { false }

      it 'makes no changes' do
        response = subject.perform
        changed_split_times = []
        validate_response(response, changed_split_times)
        validate_no_stops
      end
    end

    context 'when multiple split_times have a stopped_here flag set to true, and stop_status is false' do
      let(:split_time_1) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_1, bitkey: in_bitkey, time_from_start: 0, stopped_here: false) }
      let(:split_time_2) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_2, bitkey: in_bitkey, time_from_start: 10000, stopped_here: false) }
      let(:split_time_3) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_2, bitkey: out_bitkey, time_from_start: 11000, stopped_here: true) }
      let(:split_time_4) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_3, bitkey: in_bitkey, time_from_start: 20000, stopped_here: true) }
      let(:split_time_5) { build_stubbed(:split_time, effort: effort, lap: 1, split: split_3, bitkey: out_bitkey, time_from_start: 20000, stopped_here: true) }
      let(:stop_status) { false }

      it 'sets all split_times stopped_here to false' do
        response = subject.perform
        changed_split_times = [split_time_3, split_time_4, split_time_5]
        validate_response(response, changed_split_times)
        validate_no_stops
      end
    end

    def validate_response(response, changed_split_times)
      expect(response.resources).to match_array(changed_split_times)
    end

    def validate_stops(split_time)
      effort.split_times.each do |st|
        expect(st.stopped_here).to eq(st == split_time)
      end
    end

    def validate_no_stops
      effort.split_times.each do |st|
        expect(st.stopped_here).to eq(false)
      end
    end
  end
end
