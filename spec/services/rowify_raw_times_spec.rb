# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RowifyRawTimes do
  subject { RowifyRawTimes.new(event_group: event_group, raw_times: subject_raw_times) }

  let(:event_group) { event_1.event_group }

  let(:effort_1) { event_1.efforts.order(:bib_number).first }
  let(:effort_2) { event_2.efforts.order(:bib_number).first }
  let(:bib_number_1) { effort_1.bib_number.to_s }
  let(:bib_number_2) { effort_2.bib_number.to_s }
  let(:split_name_1) { event_1.ordered_splits.second.base_name }
  let(:split_name_2) { event_2.ordered_splits.third.base_name }

  let!(:raw_time_1) { create(:raw_time, :with_absolute_time, event_group: event_group, bib_number: bib_number_1, split_name: split_name_1, bitkey: 1, stopped_here: false) }
  let!(:raw_time_2) { create(:raw_time, :with_absolute_time, event_group: event_group, bib_number: bib_number_1, split_name: split_name_1, bitkey: 64, stopped_here: true) }
  let!(:raw_time_3) { create(:raw_time, :with_absolute_time, event_group: event_group, bib_number: bib_number_2, split_name: split_name_1, bitkey: 1, with_pacer: true) }
  let!(:raw_time_4) { create(:raw_time, :with_absolute_time, event_group: event_group, bib_number: bib_number_2, split_name: split_name_1, bitkey: 64, with_pacer: true) }
  let!(:raw_time_5) { create(:raw_time, :with_absolute_time, event_group: event_group, bib_number: bib_number_1, split_name: split_name_2, bitkey: 1) }
  let!(:raw_time_6) { create(:raw_time, :with_absolute_time, event_group: event_group, bib_number: bib_number_1, split_name: split_name_2, bitkey: 64) }
  let!(:raw_time_7) { create(:raw_time, :with_absolute_time, event_group: event_group, bib_number: bib_number_1, split_name: split_name_1, bitkey: 64) }
  let!(:raw_time_8) { create(:raw_time, :with_absolute_time, event_group: event_group, bib_number: '55', split_name: split_name_1, bitkey: 64) }

  let(:raw_time_rows) { subject.build }
  let(:raw_time_pairs) { raw_time_rows.map(&:raw_times) }

  before do
    allow(FindExpectedLap).to receive(:perform)
  end

  describe '#build' do
    context 'for a single-lap event group' do
      let!(:event_1) { events(:sum_100k) }
      let!(:event_2) { events(:sum_55k) }

      context 'when all bib_numbers match' do
        let(:subject_raw_times) { event_group.raw_times.where(id: [raw_time_1, raw_time_2, raw_time_3, raw_time_4, raw_time_5, raw_time_6, raw_time_7]).with_relation_ids }

        it 'groups raw_times by split name and adds lap to them' do
          raw_time_rows = subject.build
          expect(raw_time_rows.size).to eq(4)
          expect(raw_time_rows).to all be_a(RawTimeRow)
          expect(raw_time_rows.map(&:effort)).to match_array([effort_1, effort_2, effort_1, effort_1])
          expect(raw_time_rows.map(&:event)).to match_array([event_1, event_2, event_1, event_1])

          raw_time_pairs = raw_time_rows.map(&:raw_times)
          expect(raw_time_pairs.size).to eq(4)
          expect(raw_time_pairs).to match_array([[raw_time_1, raw_time_2], [raw_time_3, raw_time_4], [raw_time_5, raw_time_6], [raw_time_7]])
          expect(raw_time_pairs.flatten.map(&:lap)).to all eq(1)
          expect(FindExpectedLap).not_to have_received(:perform)
        end
      end

      context 'when some bib_numbers do not match' do
        let(:subject_raw_times) { event_group.raw_times.where(id: [raw_time_1, raw_time_2, raw_time_3, raw_time_4, raw_time_5, raw_time_6, raw_time_7, raw_time_8]).with_relation_ids }

        it 'groups raw_times by split name and adds lap to them' do
          expect(raw_time_rows.size).to eq(5)
          expect(raw_time_rows).to all be_a(RawTimeRow)
          expect(raw_time_rows.map(&:effort)).to match_array([effort_1, effort_2, effort_1, effort_1, nil])
          expect(raw_time_rows.map(&:event)).to match_array([event_1, event_2, event_1, event_1, nil])

          expect(raw_time_pairs.size).to eq(5)
          expect(raw_time_pairs).to match_array([[raw_time_1, raw_time_2], [raw_time_3, raw_time_4], [raw_time_5, raw_time_6], [raw_time_7], [raw_time_8]])
          expect(raw_time_pairs.flatten.map(&:lap)).to all eq(1)
          expect(FindExpectedLap).not_to have_received(:perform)
        end
      end
    end

    context 'for a multi-lap event group' do
      let(:event_1) { events(:rufa_2017_12h) }
      let(:event_2) { events(:rufa_2017_24h) }

      context 'when some bib_numbers are in a single-lap event' do
        before { event_1.update(laps_required: 1) }
        let(:subject_raw_times) { event_group.raw_times.where(id: [raw_time_1, raw_time_2, raw_time_3, raw_time_4, raw_time_5, raw_time_6, raw_time_7]).with_relation_ids }

        it 'groups raw_times by split name and calls FindExpectedLap only when necessary' do
          expect(raw_time_rows.size).to eq(4)
          expect(raw_time_rows).to all be_a(RawTimeRow)
          expect(raw_time_rows.map(&:effort)).to match_array([effort_1, effort_2, effort_1, effort_1])
          expect(raw_time_rows.map(&:event)).to match_array([event_1, event_2, event_1, event_1])

          expect(raw_time_pairs.size).to eq(4)
          expect(raw_time_pairs).to match_array([[raw_time_1, raw_time_2], [raw_time_3, raw_time_4], [raw_time_5, raw_time_6], [raw_time_7]])
          expect(subject_raw_times.size).to eq(7)
          expect(FindExpectedLap).to have_received(:perform).exactly(2).times # Only for effort_2, which is in event_2
        end
      end

      context 'when bib_numbers have a lap already attached' do
        let(:subject_raw_times) { event_group.raw_times.where(id: [raw_time_3, raw_time_4]).with_relation_ids }
        before { subject_raw_times.each { |rt| rt.assign_attributes(lap: 2) } }

        it 'groups raw_times by split name but does not call FindExpectedLap' do
          expect(raw_time_rows.size).to eq(1)
          raw_time_row = raw_time_rows.first
          expect(raw_time_row).to be_a(RawTimeRow)
          expect(raw_time_row.effort).to eq(effort_2)
          expect(raw_time_row.event).to eq(event_2)

          expect(raw_time_pairs.size).to eq(1)
          expect(raw_time_pairs).to eq([[raw_time_3, raw_time_4]])
          expect(subject_raw_times.size).to eq(2)
          expect(FindExpectedLap).to have_received(:perform).exactly(0).times # Because lap was already assigned
        end
      end
    end
  end
end
