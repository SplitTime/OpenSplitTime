require 'rails_helper'

RSpec.describe EnrichRawTimeRow do
  subject { EnrichRawTimeRow.new(event_group: event_group, raw_time_row: request_row, times_container: times_container) }
  let(:request_row) { RawTimeRow.new(request_raw_times) }
  let(:request_raw_times) { [raw_time_1, raw_time_2].compact }
  let(:times_container) { SegmentTimesContainer.new(calc_model: :stats) }

  let!(:event_group) { create(:event_group) }
  let!(:course) { create(:course) }
  let!(:cunningham_split) { create(:split, course: course, base_name: 'Cunningham') }
  let!(:maggie_split) { create(:split, course: course, base_name: 'Maggie') }
  let(:splits) { [cunningham_split, maggie_split] }

  let!(:effort_1) { create(:effort, event: event_1, bib_number: 10) }
  let!(:effort_2) { create(:effort, event: event_2, bib_number: 11) }

  let(:errors) { [] }

  before do
    allow(VerifyRawTimeRow).to receive(:perform)
    allow(FindExpectedLap).to receive(:perform)
    event_1.splits << splits
    event_2.splits << splits
  end

  describe '#perform' do
    context 'for a single-lap event group' do
      let!(:event_1) { create(:event, event_group: event_group, course: course, laps_required: 1) }
      let!(:event_2) { create(:event, event_group: event_group, course: course, laps_required: 1) }

      context 'when bib_number and split_name are found' do
        let(:raw_time_1) { build_stubbed(:raw_time, event_group: nil, bib_number: '10', split_name: 'Cunningham', sub_split_kind: 'in', stopped_here: false) }
        let(:raw_time_2) { build_stubbed(:raw_time, event_group: nil, bib_number: '10', split_name: 'Cunningham', sub_split_kind: 'out', stopped_here: true) }

        it 'adds lap to raw_times, and verifies them' do
          expect(request_raw_times.map(&:lap)).to all be_nil

          result_row = subject.perform
          expect(result_row).to be_a(RawTimeRow)
          expect(result_row.raw_times.map(&:lap)).to all eq(1)
          expect(VerifyRawTimeRow).to have_received(:perform).once.with(RawTimeRow.new(request_raw_times, effort_1, event_1, cunningham_split, errors), times_container: times_container)
          expect(FindExpectedLap).to have_received(:perform).exactly(0).times
        end
      end

      context 'when a single "in" raw_time is provided' do
        let(:raw_time_1) { build_stubbed(:raw_time, event_group: nil, bib_number: '10', split_name: 'Cunningham', sub_split_kind: 'in', stopped_here: false) }
        let(:raw_time_2) { nil }

        it 'adds lap to raw_times, and verifies them' do
          expect(request_raw_times.map(&:lap)).to all be_nil

          result_row = subject.perform
          expect(result_row).to be_a(RawTimeRow)
          expect(result_row.raw_times.map(&:lap)).to all eq(1)
          expect(VerifyRawTimeRow).to have_received(:perform).once.with(RawTimeRow.new(request_raw_times, effort_1, event_1, cunningham_split, errors), times_container: times_container)
          expect(FindExpectedLap).to have_received(:perform).exactly(0).times
        end
      end

      context 'when a single "out" raw_time is provided' do
        let(:raw_time_1) { nil }
        let(:raw_time_2) { build_stubbed(:raw_time, event_group: nil, bib_number: '10', split_name: 'Cunningham', sub_split_kind: 'out', stopped_here: true) }

        it 'adds lap to raw_times, and verifies them' do
          expect(request_raw_times.map(&:lap)).to all be_nil

          result_row = subject.perform
          expect(result_row).to be_a(RawTimeRow)
          expect(result_row.raw_times.map(&:lap)).to all eq(1)
          expect(VerifyRawTimeRow).to have_received(:perform).once.with(RawTimeRow.new(request_raw_times, effort_1, event_1, cunningham_split, errors), times_container: times_container)
          expect(FindExpectedLap).to have_received(:perform).exactly(0).times
        end
      end

      context 'when bib_number is not found' do
        let(:raw_time_1) { build_stubbed(:raw_time, event_group: nil, bib_number: '55', split_name: 'Cunningham', sub_split_kind: 'in', stopped_here: false) }
        let(:raw_time_2) { build_stubbed(:raw_time, event_group: nil, bib_number: '55', split_name: 'Cunningham', sub_split_kind: 'out', stopped_here: true) }

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
        let(:raw_time_1) { build_stubbed(:raw_time, event_group: nil, bib_number: '10', split_name: 'Nonexistent', sub_split_kind: 'in', stopped_here: false) }
        let(:raw_time_2) { build_stubbed(:raw_time, event_group: nil, bib_number: '10', split_name: 'Nonexistent', sub_split_kind: 'out', stopped_here: true) }

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
      let!(:event_1) { create(:event, event_group: event_group, course: course, laps_required: 1) }
      let!(:event_2) { create(:event, event_group: event_group, course: course, laps_required: 3) }

      context 'when bib_number is in a multi-lap event' do
        let(:raw_time_1) { build_stubbed(:raw_time, event_group: nil, bib_number: '11', split_name: 'Cunningham', sub_split_kind: 'in', stopped_here: false) }
        let(:raw_time_2) { build_stubbed(:raw_time, event_group: nil, bib_number: '11', split_name: 'Cunningham', sub_split_kind: 'out', stopped_here: true) }

        it 'calls FindExpectedLap, and verifies raw_times' do
          result_row = subject.perform
          expect(result_row).to be_a(RawTimeRow)
          expect(VerifyRawTimeRow).to have_received(:perform).once.with(RawTimeRow.new(request_raw_times, effort_2, event_2, cunningham_split, errors), times_container: times_container)
          expect(FindExpectedLap).to have_received(:perform).exactly(2).times
        end
      end

      context 'when raw_times have a lap already attached' do
        let(:raw_time_1) { build_stubbed(:raw_time, event_group: nil, bib_number: '11', lap: 2, split_name: 'Cunningham', sub_split_kind: 'in', stopped_here: false) }
        let(:raw_time_2) { build_stubbed(:raw_time, event_group: nil, bib_number: '11', lap: 2, split_name: 'Cunningham', sub_split_kind: 'out', stopped_here: true) }

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
