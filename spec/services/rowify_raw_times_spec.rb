require 'rails_helper'

RSpec.describe RowifyRawTimes do
  subject { RowifyRawTimes.new(event_group: event_group, raw_times: raw_times) }

  let!(:event_group) { create(:event_group) }
  let!(:course) { create(:course) }

  let!(:effort_1) { create(:effort, event: event_1, bib_number: 10) }
  let!(:effort_2) { create(:effort, event: event_2, bib_number: 11) }

  let!(:raw_time_1) { create(:raw_time, event_group: event_group, bib_number: '10', split_name: 'cunningham', bitkey: 1, stopped_here: false) }
  let!(:raw_time_2) { create(:raw_time, event_group: event_group, bib_number: '10', split_name: 'cunningham', bitkey: 64, stopped_here: true) }
  let!(:raw_time_3) { create(:raw_time, event_group: event_group, bib_number: '11', split_name: 'cunningham', bitkey: 1, with_pacer: true) }
  let!(:raw_time_4) { create(:raw_time, event_group: event_group, bib_number: '11', split_name: 'cunningham', bitkey: 64, with_pacer: true) }
  let!(:raw_time_5) { create(:raw_time, event_group: event_group, bib_number: '10', split_name: 'maggie', bitkey: 1) }
  let!(:raw_time_6) { create(:raw_time, event_group: event_group, bib_number: '10', split_name: 'maggie', bitkey: 64) }
  let!(:raw_time_7) { create(:raw_time, event_group: event_group, bib_number: '10', split_name: 'cunningham', bitkey: 64) }
  let!(:raw_time_8) { create(:raw_time, event_group: event_group, bib_number: '55', split_name: 'cunningham', bitkey: 64) }

  before do
    allow(VerifyRawTimes).to receive(:perform)
    allow(FindExpectedLap).to receive(:perform)
  end

  describe '#build' do
    context 'for a single-lap event group' do
      let!(:event_1) { create(:event, event_group: event_group, course: course, laps_required: 1) }
      let!(:event_2) { create(:event, event_group: event_group, course: course, laps_required: 1) }

      context 'when all bib_numbers match' do
        let(:raw_times) { RawTime.where(bib_number: %w(10 11)).with_relation_ids }

        it 'groups raw_times by split name, adds lap to them, and verifies them' do
          raw_time_pairs = subject.build
          expect(raw_time_pairs.size).to eq(4)
          expect(raw_time_pairs).to match_array([[raw_time_1, raw_time_2], [raw_time_3, raw_time_4], [raw_time_5, raw_time_6], [raw_time_7]])
          expect(raw_time_pairs.flatten.map(&:lap)).to all eq(1)
          expect(VerifyRawTimes).to have_received(:perform).exactly(4).times
          expect(FindExpectedLap).not_to have_received(:perform)
        end
      end

      context 'when some bib_numbers do not match' do
        let(:raw_times) { RawTime.where(bib_number: %w(10 11 55)).with_relation_ids }

        it 'groups raw_times by split name, adds lap to them, and verifies only those with a matching bib number' do
          raw_time_pairs = subject.build
          expect(raw_time_pairs.size).to eq(5)
          expect(raw_time_pairs).to match_array([[raw_time_1, raw_time_2], [raw_time_3, raw_time_4], [raw_time_5, raw_time_6], [raw_time_7], [raw_time_8]])
          expect(raw_time_pairs.flatten.map(&:lap)).to all eq(1)
          expect(VerifyRawTimes).to have_received(:perform).exactly(4).times
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
          raw_time_pairs = subject.build
          expect(raw_time_pairs.size).to eq(4)
          expect(raw_time_pairs).to match_array([[raw_time_1, raw_time_2], [raw_time_3, raw_time_4], [raw_time_5, raw_time_6], [raw_time_7]])
          expect(VerifyRawTimes).to have_received(:perform).exactly(4).times
          expect(raw_times.size).to eq(7)
          expect(FindExpectedLap).to have_received(:perform).exactly(2).times # Only for bib 11, which is in event_2
        end
      end
    end
  end
end
