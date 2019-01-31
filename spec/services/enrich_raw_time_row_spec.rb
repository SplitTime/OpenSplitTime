require 'rails_helper'

RSpec.describe EnrichRawTimeRow do
  subject { EnrichRawTimeRow.new(event_group: event_group, raw_time_row: request_row, times_container: times_container) }
  let(:request_row) { RawTimeRow.new(request_raw_times) }
  let(:request_raw_times) { [raw_time_1, raw_time_2].compact }
  let(:times_container) { SegmentTimesContainer.new(calc_model: :stats) }

  let(:errors) { [] }

  before do
    allow(VerifyRawTimeRow).to receive(:perform)
    allow(FindExpectedLap).to receive(:perform)
  end

  describe '#perform' do
    let(:event_group) { event.event_group }
    let(:effort) { event.efforts.order(:bib_number).first }
    let(:course) { event.course }
    let(:bib_number) { effort.bib_number.to_s }
    let(:base_name) { split.base_name }

    context 'for a single-lap event group' do
      let(:event) { events(:hardrock_2015) }
      let(:split) { course.splits.find_by(base_name: 'Cunningham') }

      context 'when bib_number and split_name are found' do
        let(:raw_time_1) { RawTime.new(event_group: event_group, bib_number: bib_number, entered_time: '10:00:00', split_name: base_name, sub_split_kind: 'in', stopped_here: false) }
        let(:raw_time_2) { RawTime.new(event_group: event_group, bib_number: bib_number, entered_time: '10:05:00', split_name: base_name, sub_split_kind: 'out', stopped_here: true) }

        it 'adds lap to raw_times, and verifies them' do
          expect(request_raw_times.map(&:lap)).to all be_nil
          expect(request_raw_times.map(&:stopped_here)).to eq([false, true])

          result_row = subject.perform
          expect(result_row).to be_a(RawTimeRow)
          expect(result_row.raw_times.map(&:lap)).to all eq(1)
          expect(result_row.raw_times.map(&:stopped_here)).to eq([false, true])
          expect(VerifyRawTimeRow).to have_received(:perform).once.with(RawTimeRow.new(request_raw_times, effort, event, split, errors), times_container: times_container)
          expect(FindExpectedLap).to have_received(:perform).exactly(0).times
        end
      end

      context 'when a stop is set on the first of two complete raw_times' do
        let(:raw_time_1) { RawTime.new(event_group: event_group, bib_number: bib_number, entered_time: '10:00:00', split_name: base_name, sub_split_kind: 'in', stopped_here: true) }
        let(:raw_time_2) { RawTime.new(event_group: event_group, bib_number: bib_number, entered_time: '10:05:00', split_name: base_name, sub_split_kind: 'out', stopped_here: false) }

        it 'moves the stop to the second raw_time' do
          expect(request_raw_times.map(&:stopped_here)).to eq([true, false])

          result_row = subject.perform
          expect(result_row).to be_a(RawTimeRow)
          expect(result_row.raw_times.map(&:stopped_here)).to eq([false, true])
        end
      end

      context 'when a stop is set on the first raw_time and the second raw_time has no entered_time or absolute_time' do
        let(:raw_time_1) { build_stubbed(:raw_time, event_group: event_group, bib_number: bib_number, entered_time: '10:00:00', split_name: base_name, sub_split_kind: 'in', stopped_here: true) }
        let(:raw_time_2) { build_stubbed(:raw_time, event_group: event_group, bib_number: bib_number, entered_time: nil, absolute_time: nil, split_name: base_name, sub_split_kind: 'out', stopped_here: false) }

        it 'leaves the stop on the first raw_time' do
          expect(request_raw_times.map(&:stopped_here)).to eq([true, false])

          result_row = subject.perform
          expect(result_row).to be_a(RawTimeRow)
          expect(result_row.raw_times.map(&:stopped_here)).to eq([true, false])
        end
      end

      context 'when a stop is set but no time has an entered_time' do
        let(:raw_time_1) { build_stubbed(:raw_time, event_group: event_group, bib_number: bib_number, entered_time: nil, absolute_time: nil, split_name: base_name, sub_split_kind: 'in', stopped_here: true) }
        let(:raw_time_2) { build_stubbed(:raw_time, event_group: event_group, bib_number: bib_number, entered_time: nil, absolute_time: nil, split_name: base_name, sub_split_kind: 'out', stopped_here: false) }

        it 'removes the stop' do
          expect(request_raw_times.map(&:stopped_here)).to eq([true, false])

          result_row = subject.perform
          expect(result_row).to be_a(RawTimeRow)
          expect(result_row.raw_times.map(&:stopped_here)).to eq([false, false])
        end
      end

      context 'when no stop is set' do
        let(:raw_time_1) { build_stubbed(:raw_time, event_group: event_group, bib_number: bib_number, entered_time: '10:00:00', split_name: base_name, sub_split_kind: 'in', stopped_here: false) }
        let(:raw_time_2) { build_stubbed(:raw_time, event_group: event_group, bib_number: bib_number, entered_time: '10:05:00', split_name: base_name, sub_split_kind: 'out', stopped_here: false) }

        it 'does not set a stop' do
          expect(request_raw_times.map(&:stopped_here)).to eq([false, false])

          result_row = subject.perform
          expect(result_row).to be_a(RawTimeRow)
          expect(result_row.raw_times.map(&:stopped_here)).to eq([false, false])
        end
      end

      context 'when a single "in" raw_time is provided' do
        let(:raw_time_1) { build_stubbed(:raw_time, event_group: nil, bib_number: bib_number, split_name: base_name, sub_split_kind: 'in', stopped_here: false) }
        let(:raw_time_2) { nil }

        it 'adds lap to raw_times, and verifies them' do
          expect(request_raw_times.map(&:lap)).to all be_nil

          result_row = subject.perform
          expect(result_row).to be_a(RawTimeRow)
          expect(result_row.raw_times.map(&:lap)).to all eq(1)
          expect(VerifyRawTimeRow).to have_received(:perform).once.with(RawTimeRow.new(request_raw_times, effort, event, split, errors), times_container: times_container)
          expect(FindExpectedLap).to have_received(:perform).exactly(0).times
        end
      end

      context 'when a single "out" raw_time is provided' do
        let(:raw_time_1) { nil }
        let(:raw_time_2) { build_stubbed(:raw_time, event_group: nil, bib_number: bib_number, split_name: base_name, sub_split_kind: 'out', stopped_here: true) }

        it 'adds lap to raw_times, and verifies them' do
          expect(request_raw_times.map(&:lap)).to all be_nil

          result_row = subject.perform
          expect(result_row).to be_a(RawTimeRow)
          expect(result_row.raw_times.map(&:lap)).to all eq(1)
          expect(VerifyRawTimeRow).to have_received(:perform).once.with(RawTimeRow.new(request_raw_times, effort, event, split, errors), times_container: times_container)
          expect(FindExpectedLap).to have_received(:perform).exactly(0).times
        end
      end

      context 'when bib_number is not found' do
        let(:raw_time_1) { build_stubbed(:raw_time, event_group: nil, bib_number: '9999', split_name: base_name, sub_split_kind: 'in', stopped_here: false) }
        let(:raw_time_2) { build_stubbed(:raw_time, event_group: nil, bib_number: '9999', split_name: base_name, sub_split_kind: 'out', stopped_here: true) }

        it 'adds lap to raw_times' do
          expect(request_raw_times.map(&:lap)).to all be_nil

          result_row = subject.perform
          expect(result_row).to be_a(RawTimeRow)
          expect(result_row.raw_times.map(&:lap)).to all eq(1)
          expect(VerifyRawTimeRow).to have_received(:perform).exactly(1).times
          expect(FindExpectedLap).to have_received(:perform).exactly(0).times
        end
      end

      context 'when split_name is not found' do
        let(:raw_time_1) { build_stubbed(:raw_time, event_group: nil, bib_number: bib_number, split_name: 'Nonexistent', sub_split_kind: 'in', stopped_here: false) }
        let(:raw_time_2) { build_stubbed(:raw_time, event_group: nil, bib_number: bib_number, split_name: 'Nonexistent', sub_split_kind: 'out', stopped_here: true) }

        it 'adds lap to raw_times' do
          expect(request_raw_times.map(&:lap)).to all be_nil

          result_row = subject.perform
          expect(result_row).to be_a(RawTimeRow)
          expect(result_row.raw_times.map(&:lap)).to all eq(1)
          expect(VerifyRawTimeRow).to have_received(:perform).exactly(1).times
          expect(FindExpectedLap).to have_received(:perform).exactly(0).times
        end
      end
    end

    context 'for a multi-lap event group' do
      let(:event) { events(:rufa_2017_24h) }
      let(:split) { course.splits.find_by(base_name: 'Finish') }

      context 'when raw_times do not have a lap attached' do
        let(:raw_time_1) { build_stubbed(:raw_time, event_group: event_group, bib_number: bib_number, split_name: base_name, sub_split_kind: 'in', stopped_here: false) }
        let(:raw_time_2) { build_stubbed(:raw_time, event_group: event_group, bib_number: bib_number, split_name: base_name, sub_split_kind: 'out', stopped_here: true) }

        it 'calls FindExpectedLap, and verifies raw_times' do
          result_row = subject.perform
          expect(result_row).to be_a(RawTimeRow)
          expect(VerifyRawTimeRow).to have_received(:perform).once.with(RawTimeRow.new(request_raw_times, effort, event, split, errors), times_container: times_container)
          expect(FindExpectedLap).to have_received(:perform).exactly(2).times
        end
      end

      context 'when raw_times have a lap already attached' do
        let(:raw_time_1) { build_stubbed(:raw_time, event_group: event_group, bib_number: bib_number, lap: 2, split_name: base_name, sub_split_kind: 'in', stopped_here: false) }
        let(:raw_time_2) { build_stubbed(:raw_time, event_group: event_group, bib_number: bib_number, lap: 2, split_name: base_name, sub_split_kind: 'out', stopped_here: true) }

        it 'does not call FindExpectedLap but verifies raw_times' do
          result_row = subject.perform
          expect(result_row).to be_a(RawTimeRow)
          expect(VerifyRawTimeRow).to have_received(:perform).exactly(1).times
          expect(FindExpectedLap).to have_received(:perform).exactly(0).times
        end
      end
    end
  end
end
