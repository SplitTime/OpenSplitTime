# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TimeRecordPairer do
  subject { TimeRecordPairer.new(time_records: raw_times) }
  let(:raw_time_1) { build_stubbed(:raw_time, event_group_id: event_group_id, bib_number: '10', split_name: 'Aid 1', bitkey: 1, stopped_here: false) }
  let(:raw_time_2) { build_stubbed(:raw_time, event_group_id: event_group_id, bib_number: '10', split_name: 'Aid 1', bitkey: 64, stopped_here: true) }
  let(:raw_time_3) { build_stubbed(:raw_time, event_group_id: event_group_id, bib_number: '11', split_name: 'Aid 1', bitkey: 1, with_pacer: true) }
  let(:raw_time_4) { build_stubbed(:raw_time, event_group_id: event_group_id, bib_number: '11', split_name: 'Aid 1', bitkey: 64, with_pacer: true) }
  let(:raw_time_5) { build_stubbed(:raw_time, event_group_id: event_group_id, bib_number: '10', split_name: 'Aid 2', bitkey: 1) }
  let(:raw_time_6) { build_stubbed(:raw_time, event_group_id: event_group_id, bib_number: '10', split_name: 'Aid 2', bitkey: 64) }
  let(:raw_time_7) { build_stubbed(:raw_time, event_group_id: event_group_id, bib_number: '10', split_name: 'Aid 1', bitkey: 64) }
  let(:raw_time_bad_split) { build_stubbed(:raw_time, event_group_id: event_group_id, bib_number: '10', split_id: 999, bitkey: 1) }
  let(:raw_time_wildcard_1) { build_stubbed(:raw_time, event_group_id: event_group_id, bib_number: '10*', split_name: 'Aid 1', bitkey: 1) }
  let(:raw_time_wildcard_2) { build_stubbed(:raw_time, event_group_id: event_group_id, bib_number: '10*', split_name: 'Aid 1', bitkey: 64) }

  let(:event_group_id) { 101 }

  describe '#pair' do
    context 'when all time_records can be paired' do
      let(:raw_times) { [raw_time_1, raw_time_2, raw_time_3, raw_time_4, raw_time_5, raw_time_6, raw_time_7] }

      it 'returns an array of paired time_record arrays' do
        expected = [[raw_time_1, raw_time_2], [raw_time_5, raw_time_6], [nil, raw_time_7], [raw_time_3, raw_time_4]]
        expect(subject.pair).to eq(expected)
      end

      it 'retains boolean attributes' do
        expect(subject.pair.first.map(&:stopped_here)).to eq([false, true])
        expect(subject.pair.fourth.map(&:with_pacer)).to eq([true, true])
      end
    end

    context 'when time_records contain wildcard characters' do
      let(:raw_times) { [raw_time_1, raw_time_2, raw_time_wildcard_1, raw_time_wildcard_2] }

      it 'pairs matching wildcard bib_numbers with each other but not with any other time_record' do
        expected = [[raw_time_1, raw_time_2], [raw_time_wildcard_1, raw_time_wildcard_2]]
        expect(subject.pair).to eq(expected)
      end
    end
  end
end
