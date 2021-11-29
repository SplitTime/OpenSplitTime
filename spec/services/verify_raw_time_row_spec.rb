# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VerifyRawTimeRow do
  subject { VerifyRawTimeRow.new(raw_time_row, times_container: times_container) }
  let(:raw_time_row) { RawTimeRow.new(raw_times, effort, event) }
  let(:times_container) { SegmentTimesContainer.new(calc_model: :terrain) }

  let(:event) { build_stubbed(:event, splits: splits, course: course, scheduled_start_time_local: '2018-06-23 06:00:00', laps_required: 1) }
  let(:start_time) { event&.scheduled_start_time || DateTime.parse('2018-10-31 08:00:00') }
  let(:course) { build_stubbed(:course) }
  let(:effort) { build_stubbed(:effort, event: event, split_times: split_times, bib_number: 10) }
  let(:start_split) { build_stubbed(:split, :start, course: course, base_name: 'Start') }
  let(:cunningham_split) { build_stubbed(:split, course: course, base_name: 'Cunningham', distance_from_start: 10000) }
  let(:maggie_split) { build_stubbed(:split, course: course, base_name: 'Maggie', distance_from_start: 20000) }
  let(:splits) { [start_split, cunningham_split, maggie_split] }
  let(:expected_lap_splits) { event.required_lap_splits }

  let(:split_time_1) { build_stubbed(:split_time, split: start_split, bitkey: 1, absolute_time: start_time + 0) }
  let(:split_time_2) { build_stubbed(:split_time, split: cunningham_split, bitkey: 1, absolute_time: start_time + 7200) }
  let(:split_time_3) { build_stubbed(:split_time, split: cunningham_split, bitkey: 64, absolute_time: start_time + 7300) }
  let(:split_time_4) { build_stubbed(:split_time, split: maggie_split, bitkey: 1, absolute_time: start_time + 15000) }
  let(:split_time_5) { build_stubbed(:split_time, split: maggie_split, bitkey: 64, absolute_time: start_time + 15100) }

  let(:raw_times) { [raw_time_1, raw_time_2].compact }

  let(:raw_time_1) { build_stubbed(:raw_time, event_group_id: 100, absolute_time: event_time_zone.parse('2018-06-23 06:00:00'), effort: effort, lap: 1, bib_number: '10', split: start_split, split_name: 'Start', bitkey: 1, stopped_here: false) }
  let(:raw_time_2) { build_stubbed(:raw_time, event_group_id: 100, absolute_time: event_time_zone.parse('2018-06-23 07:00:00'), effort: effort, lap: 1, bib_number: '10', split: cunningham_split, split_name: 'Cunningham', bitkey: 1, stopped_here: false) }
  let(:raw_time_3) { build_stubbed(:raw_time, event_group_id: 100, absolute_time: event_time_zone.parse('2018-06-23 07:01:00'), effort: effort, lap: 1, bib_number: '10', split: cunningham_split, split_name: 'Cunningham', bitkey: 64, stopped_here: false) }
  let(:raw_time_4) { build_stubbed(:raw_time, event_group_id: 100, absolute_time: nil, entered_time: '08:30:00', effort: effort, lap: 1, bib_number: '10', split: maggie_split, split_name: 'Maggie', bitkey: 1, stopped_here: false) }
  let(:raw_time_5) { build_stubbed(:raw_time, event_group_id: 100, absolute_time: nil, entered_time: '08:31:00', effort: effort, lap: 1, bib_number: '10', split: maggie_split, split_name: 'Maggie', bitkey: 64, stopped_here: true) }
  let(:raw_time_6) { build_stubbed(:raw_time, event_group_id: 100, absolute_time: nil, entered_time: '08:31:00', effort: effort, lap: 1, bib_number: '11', split: maggie_split, split_name: 'Maggie', bitkey: 64, stopped_here: true) }
  let(:raw_time_7) { build_stubbed(:raw_time, event_group_id: 100, absolute_time: nil, entered_time: '08:mm:ss', effort: effort, lap: 1, bib_number: '10', split: cunningham_split, split_name: 'Cunningham', bitkey: 1, stopped_here: false) }
  let(:raw_time_8) { build_stubbed(:raw_time, event_group_id: 100, absolute_time: nil, entered_time: '08:mm:ss', effort: effort, lap: 1, bib_number: '10', split: cunningham_split, split_name: 'Cunningham', bitkey: 1, stopped_here: false) }

  let(:time_zone) { event&.home_time_zone || 'Arizona' }
  let(:event_time_zone) { ActiveSupport::TimeZone[time_zone] }

  before { split_times.each { |st| st.effort = effort } }

  describe '#perform' do
    context 'when all times exist on the effort' do
      let(:split_times) { [split_time_1, split_time_2, split_time_3, split_time_4, split_time_5] }
      let(:raw_time_1) { build_stubbed(:raw_time, event_group_id: 100, absolute_time: event_time_zone.parse('2018-06-23 07:00:00'), effort: effort, lap: 1, bib_number: '10', split: cunningham_split, split_name: 'Cunningham', bitkey: 1, stopped_here: false) }
      let(:raw_time_2) { build_stubbed(:raw_time, event_group_id: 100, absolute_time: event_time_zone.parse('2018-06-23 07:01:00'), effort: effort, lap: 1, bib_number: '10', split: cunningham_split, split_name: 'Cunningham', bitkey: 64, stopped_here: false) }

      it 'returns a raw_time_row with split_time_exists attribute equal to true and adds new_split_time to each raw_time' do
        allow(Interactors::SetEffortStatus).to receive(:perform)
        expect(raw_times.size).to eq(2)
        expect(raw_times.map(&:split_time_exists)).to all be_nil

        result_row = subject.perform
        expect(result_row.errors).to be_empty

        result_raw_times = result_row.raw_times
        expect(result_raw_times.size).to eq(2)
        expect(result_raw_times).to all be_a(RawTime)
        expect(result_raw_times.map(&:split_time_exists)).to eq([true, true])

        new_split_times = result_raw_times.map(&:new_split_time)
        expect(new_split_times).to all be_a(SplitTime)
        expect(new_split_times.map(&:effort_id)).to all eq(effort.id)
        expect(new_split_times.map(&:lap)).to all eq(1)
        expect(new_split_times.map(&:split_id)).to all eq(cunningham_split.id)
        expect(new_split_times.map(&:bitkey)).to eq([1, 64])
        expect(new_split_times.map(&:absolute_time)).to eq([60.minutes, 61.minutes].map { |e| start_time + e })

        expect(Interactors::SetEffortStatus).to have_received(:perform).once
      end

      it 'does not change the data_status of the split_times on the effort' do
        expect(effort.split_times.map(&:data_status)).to all be_nil
        subject.perform
        expect(effort.split_times.map(&:data_status)).to all be_nil
      end
    end

    context 'when only an out time is provided' do
      let(:split_times) { [split_time_1, split_time_2, split_time_3, split_time_4, split_time_5] }
      let(:raw_time_1) { build_stubbed(:raw_time, event_group_id: 100, absolute_time: event_time_zone.parse('2018-06-23 07:01:00'), effort: effort, lap: 1, bib_number: '10', split: cunningham_split, split_name: 'Cunningham', bitkey: 64, stopped_here: false) }
      let(:raw_time_2) { nil }

      it 'returns a raw_time_row with split_time_exists attribute equal to 1 and adds new_split_time to each raw_time' do
        allow(Interactors::SetEffortStatus).to receive(:perform)
        expect(raw_times.size).to eq(1)
        expect(raw_times.map(&:split_time_exists)).to all be_nil

        result_row = subject.perform
        result_raw_times = result_row.raw_times
        expect(result_raw_times.size).to eq(1)
        expect(result_raw_times).to all be_a(RawTime)
        expect(result_raw_times.map(&:split_time_exists)).to eq([true])

        new_split_times = result_raw_times.map(&:new_split_time)
        expect(new_split_times).to all be_a(SplitTime)
        expect(new_split_times.map(&:effort_id)).to all eq(effort.id)
        expect(new_split_times.map(&:lap)).to all eq(1)
        expect(new_split_times.map(&:split_id)).to all eq(cunningham_split.id)
        expect(new_split_times.map(&:bitkey)).to eq([64])
        expect(new_split_times.map(&:absolute_time)).to eq([61.minutes].map { |e| start_time + e })

        expect(Interactors::SetEffortStatus).to have_received(:perform).once
      end
    end

    context 'when raw_times are provided with entered_time' do
      let(:split_times) { [split_time_1, split_time_2, split_time_3, split_time_4, split_time_5] }
      let(:raw_time_1) { build_stubbed(:raw_time, event_group_id: 100, absolute_time: nil, entered_time: '08:30:00', effort: effort, lap: 1, bib_number: '10', split: maggie_split, split_name: 'Maggie', bitkey: 1, stopped_here: false) }
      let(:raw_time_2) { build_stubbed(:raw_time, event_group_id: 100, absolute_time: nil, entered_time: '08:31:00', effort: effort, lap: 1, bib_number: '10', split: maggie_split, split_name: 'Maggie', bitkey: 64, stopped_here: true) }

      it 'returns a raw_time_row with attributes set and calculates absolute_time correctly' do
        allow(Interactors::SetEffortStatus).to receive(:perform)
        expect(raw_times.size).to eq(2)
        expect(raw_times.map(&:split_time_exists)).to all be_nil

        result_row = subject.perform
        result_raw_times = result_row.raw_times
        expect(result_raw_times.size).to eq(2)
        expect(result_raw_times).to all be_a(RawTime)
        expect(result_raw_times.map(&:split_time_exists)).to eq([true, true])

        new_split_times = result_raw_times.map(&:new_split_time)
        expect(new_split_times).to all be_a(SplitTime)
        expect(new_split_times.map(&:effort_id)).to all eq(effort.id)
        expect(new_split_times.map(&:lap)).to all eq(1)
        expect(new_split_times.map(&:split_id)).to all eq(maggie_split.id)
        expect(new_split_times.map(&:bitkey)).to eq([1, 64])
        expect(new_split_times.map(&:absolute_time)).to eq([150.minutes, 151.minutes].map { |e| start_time + e })

        expect(Interactors::SetEffortStatus).to have_received(:perform).once
      end
    end

    context 'when a raw_time is provided with an invalid entered_time' do
      let(:split_times) { [split_time_1, split_time_2, split_time_3, split_time_4, split_time_5] }
      let(:raw_time_1) { build_stubbed(:raw_time, event_group_id: 100, absolute_time: nil, entered_time: '99:99:99', effort: effort, lap: 1, bib_number: '10', split: cunningham_split, split_name: 'Cunningham', bitkey: 1, stopped_here: false) }
      let(:raw_time_2) { nil }

      it 'returns a raw_time_row with attributes set, attaches a split_time with absolute_time: nil, and does not set effort status' do
        allow(Interactors::SetEffortStatus).to receive(:perform)
        expect(raw_times.size).to eq(1)
        expect(raw_times.map(&:split_time_exists)).to all be_nil

        result_row = subject.perform
        result_raw_times = result_row.raw_times
        expect(result_raw_times.size).to eq(1)
        expect(result_raw_times).to all be_a(RawTime)
        expect(result_raw_times.map(&:split_time_exists)).to eq([true])

        new_split_times = result_raw_times.map(&:new_split_time)
        expect(new_split_times.size).to eq(1)
        new_split_time = new_split_times.first
        expect(new_split_time).to be_a(SplitTime)
        expect(new_split_time.absolute_time).to be_nil

        expect(Interactors::SetEffortStatus).not_to have_received(:perform)
      end
    end

    context 'when raw_times are provided with one valid and one invalid entered_time' do
      let(:split_times) { [split_time_1, split_time_2, split_time_3, split_time_4, split_time_5] }
      let(:raw_time_1) { build_stubbed(:raw_time, event_group_id: 100, absolute_time: nil, entered_time: '99:99:99', effort: effort, lap: 1, bib_number: '10', split: cunningham_split, split_name: 'Cunningham', bitkey: 1, stopped_here: false) }
      let(:raw_time_2) { build_stubbed(:raw_time, event_group_id: 100, absolute_time: nil, entered_time: '08:00:00', effort: effort, lap: 1, bib_number: '10', split: cunningham_split, split_name: 'Cunningham', bitkey: 64, stopped_here: false) }

      it 'returns a raw_time_row with attributes set, attaches a split_time with absolute_time: nil, and does not set effort status' do
        allow(Interactors::SetEffortStatus).to receive(:perform)
        expect(raw_times.size).to eq(2)
        expect(raw_times.map(&:split_time_exists)).to all be_nil

        result_row = subject.perform
        result_raw_times = result_row.raw_times
        expect(result_raw_times.size).to eq(2)
        expect(result_raw_times).to all be_a(RawTime)
        expect(raw_times.map(&:split_time_exists)).to eq([true, true])

        new_split_times = result_raw_times.map(&:new_split_time)
        expect(new_split_times.size).to eq(2)
        expect(new_split_times).to all be_a(SplitTime)
        expect(new_split_times.map(&:absolute_time)).to eq([nil, start_time + 2.hours])

        expect(Interactors::SetEffortStatus).to have_received(:perform).once
      end
    end

    context 'when no times exist on the effort' do
      let(:split_times) { [split_time_1] }
      let(:raw_times) { [raw_time_2, raw_time_3] }

      it 'returns a raw_time_row with split_time_exists attribute equal to 0' do
        allow(Interactors::SetEffortStatus).to receive(:perform)
        expect(raw_times.size).to eq(2)
        expect(raw_times.map(&:split_time_exists)).to all be_nil

        result_row = subject.perform
        result_raw_times = result_row.raw_times
        expect(result_raw_times.size).to eq(2)
        expect(result_raw_times).to all be_a(RawTime)
        expect(result_raw_times.map(&:split_time_exists)).to eq([false, false])

        new_split_times = result_raw_times.map(&:new_split_time)
        expect(new_split_times).to all be_a(SplitTime)
        expect(new_split_times.map(&:effort_id)).to all eq(effort.id)
        expect(new_split_times.map(&:lap)).to all eq(1)
        expect(new_split_times.map(&:split_id)).to all eq(cunningham_split.id)
        expect(new_split_times.map(&:bitkey)).to eq([1, 64])
        expect(new_split_times.map(&:absolute_time)).to eq([60.minutes, 61.minutes].map { |e| start_time + e })

        expect(Interactors::SetEffortStatus).to have_received(:perform).once
      end
    end

    context 'when one time exists on the effort and one does not' do
      let(:split_times) { [split_time_1, split_time_3] }
      let(:raw_times) { [raw_time_2, raw_time_3] }

      it 'returns a raw_time_row with split_time_exists attribute equal to expected values' do
        allow(Interactors::SetEffortStatus).to receive(:perform)
        expect(raw_times.size).to eq(2)
        expect(raw_times.map(&:split_time_exists)).to all be_nil

        result_row = subject.perform
        result_raw_times = result_row.raw_times
        expect(result_raw_times.size).to eq(2)
        expect(result_raw_times).to all be_a(RawTime)
        expect(result_raw_times.map(&:split_time_exists)).to eq([false, true])

        new_split_times = result_raw_times.map(&:new_split_time)
        expect(new_split_times).to all be_a(SplitTime)
        expect(new_split_times.map(&:effort_id)).to all eq(effort.id)
        expect(new_split_times.map(&:lap)).to all eq(1)
        expect(new_split_times.map(&:split_id)).to all eq(cunningham_split.id)
        expect(new_split_times.map(&:bitkey)).to eq([1, 64])
        expect(new_split_times.map(&:absolute_time)).to eq([60.minutes, 61.minutes].map { |e| start_time + e })

        expect(Interactors::SetEffortStatus).to have_received(:perform).once
      end
    end

    context 'when a single raw_time is present' do
      let(:split_times) { [split_time_1, split_time_2] }
      let(:raw_times) { [raw_time_1] }

      it 'returns a a raw_time_row with expected split_time_exists and new_split_time' do
        allow(Interactors::SetEffortStatus).to receive(:perform)
        expect(raw_times.size).to eq(1)
        expect(raw_times.map(&:split_time_exists)).to all be_nil

        result_row = subject.perform
        result_raw_times = result_row.raw_times
        expect(result_raw_times.size).to eq(1)
        expect(result_raw_times).to all be_a(RawTime)
        expect(result_raw_times.map(&:split_time_exists)).to eq([true])

        new_split_times = result_raw_times.map(&:new_split_time)
        expect(new_split_times).to all be_a(SplitTime)
        expect(new_split_times.map(&:effort_id)).to all eq(effort.id)
        expect(new_split_times.map(&:lap)).to all eq(1)
        expect(new_split_times.map(&:split_id)).to all eq(start_split.id)
        expect(new_split_times.map(&:bitkey)).to eq([1])
        expect(new_split_times.map(&:absolute_time)).to eq([0].map { |e| start_time + e })

        expect(Interactors::SetEffortStatus).to have_received(:perform).once
      end
    end

    context 'when an event has unlimited laps' do
      let(:event) { build_stubbed(:event, splits: splits, course: course, scheduled_start_time_local: '2018-06-23 06:00:00', laps_required: 0) }
      let(:split_times) { [split_time_1, split_time_2] }
      let(:raw_times) { [raw_time_1] }

      it 'returns a a raw_time_row with expected split_time_exists and new_split_time' do
        allow(Interactors::SetEffortStatus).to receive(:perform)
        expect(raw_times.size).to eq(1)
        expect(raw_times.map(&:split_time_exists)).to all be_nil

        result_row = subject.perform
        result_raw_times = result_row.raw_times
        expect(result_raw_times.size).to eq(1)
        expect(result_raw_times).to all be_a(RawTime)
        expect(result_raw_times.map(&:split_time_exists)).to eq([true])

        new_split_times = result_raw_times.map(&:new_split_time)
        expect(new_split_times).to all be_a(SplitTime)
        expect(new_split_times.map(&:effort_id)).to all eq(effort.id)
        expect(new_split_times.map(&:lap)).to all eq(1)
        expect(new_split_times.map(&:split_id)).to all eq(start_split.id)
        expect(new_split_times.map(&:bitkey)).to eq([1])
        expect(new_split_times.map(&:absolute_time)).to eq([0].map { |e| start_time + e })

        expect(Interactors::SetEffortStatus).to have_received(:perform).once
      end
    end

    context 'when raw_times are not from the same split' do
      let(:split_times) { [split_time_1, split_time_2] }
      let(:raw_times) { [raw_time_1, raw_time_2] }

      it 'returns a raw_time_row with a descriptive error' do
        allow(Interactors::SetEffortStatus).to receive(:perform)

        result_row = subject.perform
        expect(result_row.errors).to include('mismatched split names')

        result_raw_times = result_row.raw_times
        expect(result_raw_times.size).to eq(2)
        expect(result_raw_times).to all be_a(RawTime)
        expect(result_raw_times.map(&:split_time_exists)).to all be_nil

        new_split_times = result_raw_times.map(&:new_split_time)
        expect(new_split_times).to all be_nil

        expect(Interactors::SetEffortStatus).not_to have_received(:perform)
      end
    end

    context 'when raw_times do not have the same bib number' do
      let(:split_times) { [split_time_1, split_time_2] }
      let(:raw_times) { [raw_time_4, raw_time_6] }

      it 'returns a raw_time_row with a descriptive error' do
        allow(Interactors::SetEffortStatus).to receive(:perform)

        result_row = subject.perform
        expect(result_row.errors).to include('mismatched bib numbers')

        result_raw_times = result_row.raw_times
        expect(result_raw_times.size).to eq(2)
        expect(result_raw_times).to all be_a(RawTime)
        expect(result_raw_times.map(&:split_time_exists)).to all be_nil

        new_split_times = result_raw_times.map(&:new_split_time)
        expect(new_split_times).to all be_nil

        expect(Interactors::SetEffortStatus).not_to have_received(:perform)
      end
    end

    context 'when raw_times are not present' do
      let(:split_times) { [split_time_1, split_time_2] }
      let(:raw_times) { [] }

      it 'returns a raw_time_row with a descriptive error' do
        allow(Interactors::SetEffortStatus).to receive(:perform)

        result_row = subject.perform
        expect(result_row.errors).to include('missing raw times')

        result_raw_times = result_row.raw_times
        expect(result_raw_times.size).to eq(0)

        expect(Interactors::SetEffortStatus).not_to have_received(:perform)
      end
    end

    context 'when effort is not present' do
      let(:split_times) { [split_time_1, split_time_2] }
      let(:raw_times) { [raw_time_1, raw_time_2] }
      let(:effort) { nil }

      it 'returns a raw_time_row with a descriptive error' do
        allow(Interactors::SetEffortStatus).to receive(:perform)

        result_row = subject.perform
        expect(result_row.errors).to include('missing effort')

        result_raw_times = result_row.raw_times
        expect(result_raw_times.size).to eq(2)
        expect(result_raw_times).to all be_a(RawTime)
        expect(result_raw_times.map(&:split_time_exists)).to all be_nil

        new_split_times = result_raw_times.map(&:new_split_time)
        expect(new_split_times).to all be_nil

        expect(Interactors::SetEffortStatus).not_to have_received(:perform)
      end
    end

    context 'when event is not present' do
      let(:split_times) { [split_time_1, split_time_2] }
      let(:raw_times) { [raw_time_1, raw_time_2] }
      let(:event) { nil }

      it 'returns a raw_time_row with a descriptive error' do
        allow(Interactors::SetEffortStatus).to receive(:perform)

        result_row = subject.perform
        expect(result_row.errors).to include('missing event')

        result_raw_times = result_row.raw_times
        expect(result_raw_times.size).to eq(2)
        expect(result_raw_times).to all be_a(RawTime)
        expect(result_raw_times.map(&:split_time_exists)).to all be_nil

        new_split_times = result_raw_times.map(&:new_split_time)
        expect(new_split_times).to all be_nil

        expect(Interactors::SetEffortStatus).not_to have_received(:perform)
      end
    end
  end
end
