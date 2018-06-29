require 'rails_helper'

RSpec.describe RowifyRawTimes do
  subject { RowifyRawTimes.new(event_group: event_group, raw_times: raw_times) }

  let!(:event_group) { create(:event_group) }
  let!(:course) { create(:course) }
  let!(:cunningham_split) { create(:split, course: course, base_name: 'Cunningham') }
  let!(:maggie_split) { create(:split, course: course, base_name: 'Maggie') }
  let(:splits) { [cunningham_split, maggie_split] }

  let!(:effort_1) { create(:effort, event: event_1, bib_number: 10) }
  let!(:effort_2) { create(:effort, event: event_2, bib_number: 11) }

  let!(:raw_time_1) { create(:raw_time, event_group: event_group, bib_number: '10', split_name: 'Cunningham', bitkey: 1, stopped_here: false) }
  let!(:raw_time_2) { create(:raw_time, event_group: event_group, bib_number: '10', split_name: 'Cunningham', bitkey: 64, stopped_here: true) }
  let!(:raw_time_3) { create(:raw_time, event_group: event_group, bib_number: '11', split_name: 'Cunningham', bitkey: 1, with_pacer: true) }
  let!(:raw_time_4) { create(:raw_time, event_group: event_group, bib_number: '11', split_name: 'Cunningham', bitkey: 64, with_pacer: true) }
  let!(:raw_time_5) { create(:raw_time, event_group: event_group, bib_number: '10', split_name: 'Maggie', bitkey: 1) }
  let!(:raw_time_6) { create(:raw_time, event_group: event_group, bib_number: '10', split_name: 'Maggie', bitkey: 64) }
  let!(:raw_time_7) { create(:raw_time, event_group: event_group, bib_number: '10', split_name: 'Cunningham', bitkey: 64) }
  let!(:raw_time_8) { create(:raw_time, event_group: event_group, bib_number: '55', split_name: 'Cunningham', bitkey: 64) }

  let(:raw_time_rows) { subject.build }
  let(:raw_time_pairs) { raw_time_rows.map(&:raw_times) }

  before do
    allow(VerifyRawTimeRow).to receive(:perform)
    allow(FindExpectedLap).to receive(:perform)
    event_1.splits << splits
    event_2.splits << splits
  end

  describe '#build' do
    context 'for a single-lap event group' do
      let!(:event_1) { create(:event, event_group: event_group, course: course, laps_required: 1) }
      let!(:event_2) { create(:event, event_group: event_group, course: course, laps_required: 1) }

      context 'when all bib_numbers match' do
        let(:raw_times) { RawTime.where(bib_number: %w(10 11)).with_relation_ids }

        it 'groups raw_times by split name, adds lap to them, and verifies them' do
          raw_time_rows = subject.build
          expect(raw_time_rows.size).to eq(4)
          expect(raw_time_rows).to all be_a(RawTimeRow)
          expect(raw_time_rows.map(&:effort)).to match_array([effort_1, effort_2, effort_1, effort_1])
          expect(raw_time_rows.map(&:event)).to match_array([event_1, event_2, event_1, event_1])

          raw_time_pairs = raw_time_rows.map(&:raw_times)
          expect(raw_time_pairs.size).to eq(4)
          expect(raw_time_pairs).to match_array([[raw_time_1, raw_time_2], [raw_time_3, raw_time_4], [raw_time_5, raw_time_6], [raw_time_7]])
          expect(raw_time_pairs.flatten.map(&:lap)).to all eq(1)
          expect(VerifyRawTimeRow).to have_received(:perform).exactly(4).times
          expect(FindExpectedLap).not_to have_received(:perform)
        end
      end

      context 'when some bib_numbers do not match' do
        let(:raw_times) { RawTime.where(bib_number: %w(10 11 55)).with_relation_ids }

        it 'groups raw_times by split name, adds lap to them, and verifies them' do
          expect(raw_time_rows.size).to eq(5)
          expect(raw_time_rows).to all be_a(RawTimeRow)
          expect(raw_time_rows.map(&:effort)).to match_array([effort_1, effort_2, effort_1, effort_1, nil])
          expect(raw_time_rows.map(&:event)).to match_array([event_1, event_2, event_1, event_1, nil])

          expect(raw_time_pairs.size).to eq(5)
          expect(raw_time_pairs).to match_array([[raw_time_1, raw_time_2], [raw_time_3, raw_time_4], [raw_time_5, raw_time_6], [raw_time_7], [raw_time_8]])
          expect(raw_time_pairs.flatten.map(&:lap)).to all eq(1)
          expect(VerifyRawTimeRow).to have_received(:perform).exactly(5).times
          expect(FindExpectedLap).not_to have_received(:perform)
        end
      end
    end

    context 'for a multi-lap event group' do
      let!(:event_1) { create(:event, event_group: event_group, course: course, laps_required: 1) }
      let!(:event_2) { create(:event, event_group: event_group, course: course, laps_required: 3) }

      context 'when some bib_numbers are in a single-lap event' do
        let(:raw_times) { RawTime.where(bib_number: %w(10 11)).with_relation_ids }

        it 'groups raw_times by split name, calls FindExpectedLap only when necessary, and verifies them' do
          expect(raw_time_rows.size).to eq(4)
          expect(raw_time_rows).to all be_a(RawTimeRow)
          expect(raw_time_rows.map(&:effort)).to match_array([effort_1, effort_2, effort_1, effort_1])
          expect(raw_time_rows.map(&:event)).to match_array([event_1, event_2, event_1, event_1])

          expect(raw_time_pairs.size).to eq(4)
          expect(raw_time_pairs).to match_array([[raw_time_1, raw_time_2], [raw_time_3, raw_time_4], [raw_time_5, raw_time_6], [raw_time_7]])
          expect(VerifyRawTimeRow).to have_received(:perform).exactly(4).times
          expect(raw_times.size).to eq(7)
          expect(FindExpectedLap).to have_received(:perform).exactly(2).times # Only for bib 11, which is in event_2
        end
      end

      context 'when bib_numbers have a lap already attached' do
        let(:raw_times) { RawTime.where(bib_number: '11').with_relation_ids }
        before { raw_times.each { |rt| rt.lap = 2 } }

        it 'groups raw_times by split name, does not call FindExpectedLap, and verifies them' do
          expect(raw_time_rows.size).to eq(1)
          raw_time_row = raw_time_rows.first
          expect(raw_time_row).to be_a(RawTimeRow)
          expect(raw_time_row.effort).to eq(effort_2)
          expect(raw_time_row.event).to eq(event_2)

          expect(raw_time_pairs.size).to eq(1)
          expect(raw_time_pairs).to eq([[raw_time_3, raw_time_4]])
          expect(VerifyRawTimeRow).to have_received(:perform).exactly(1).times
          expect(raw_times.size).to eq(2)
          expect(FindExpectedLap).to have_received(:perform).exactly(0).times # Because lap was already assigned
        end
      end
    end
  end
end
