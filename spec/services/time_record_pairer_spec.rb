require 'rails_helper'

RSpec.describe TimeRecordPairer do
  let(:event) { build_stubbed(:event, id: 1001) }

  subject { TimeRecordPairer.new(event: event, time_records: live_times) }
  let(:live_time_1) { build_stubbed(:live_time, event_id: event.id, bib_number: '10', split_id: 101, bitkey: 1, stopped_here: false) }
  let(:live_time_2) { build_stubbed(:live_time, event_id: event.id, bib_number: '10', split_id: 101, bitkey: 64, stopped_here: true) }
  let(:live_time_3) { build_stubbed(:live_time, event_id: event.id, bib_number: '11', split_id: 101, bitkey: 1, with_pacer: true) }
  let(:live_time_4) { build_stubbed(:live_time, event_id: event.id, bib_number: '11', split_id: 101, bitkey: 64, with_pacer: true) }
  let(:live_time_5) { build_stubbed(:live_time, event_id: event.id, bib_number: '10', split_id: 102, bitkey: 1) }
  let(:live_time_6) { build_stubbed(:live_time, event_id: event.id, bib_number: '10', split_id: 102, bitkey: 64) }
  let(:live_time_7) { build_stubbed(:live_time, event_id: event.id, bib_number: '10', split_id: 101, bitkey: 64) }
  let(:live_time_bad_split) { build_stubbed(:live_time, event_id: event.id, bib_number: '10', split_id: 999, bitkey: 1) }
  let(:live_time_wildcard_1) { build_stubbed(:live_time, event_id: event.id, bib_number: '10*', split_id: 101, bitkey: 1) }
  let(:live_time_wildcard_2) { build_stubbed(:live_time, event_id: event.id, bib_number: '10*', split_id: 101, bitkey: 64) }

  describe '#pair' do
    context 'when all time_records can be paired' do
      let(:live_times) { [live_time_1, live_time_2, live_time_3, live_time_4, live_time_5, live_time_6, live_time_7] }

      it 'returns an array of paired time_record arrays' do
        expected = [[live_time_1, live_time_2], [nil, live_time_7], [live_time_3, live_time_4], [live_time_5, live_time_6]]
        expect(subject.pair).to eq(expected)
      end

      it 'retains boolean attributes' do
        expect(subject.pair.first.map(&:stopped_here)).to eq([false, true])
        expect(subject.pair.third.map(&:with_pacer)).to eq([true, true])
      end
    end

    context 'when time_records contain wildcard characters' do
      let(:live_times) { [live_time_1, live_time_2, live_time_wildcard_1, live_time_wildcard_2] }

      it 'pairs matching wildcard bib_numbers with each other but not with any other time_record' do
        expected = [[live_time_1, live_time_2], [live_time_wildcard_1, live_time_wildcard_2]]
        expect(subject.pair).to eq(expected)
      end
    end
  end
end
