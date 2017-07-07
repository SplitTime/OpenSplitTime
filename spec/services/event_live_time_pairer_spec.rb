require 'rails_helper'

RSpec.describe EventLiveTimePairer do
  subject { EventLiveTimePairer.new(event: event, live_times: live_times) }
  let(:event) { build_stubbed(:event, id: 1001) }
  let(:live_time_1) { build_stubbed(:live_time, event_id: event.id, bib_number: 10, split_id: 101, bitkey: 1) }
  let(:live_time_2) { build_stubbed(:live_time, event_id: event.id, bib_number: 10, split_id: 101, bitkey: 64) }
  let(:live_time_3) { build_stubbed(:live_time, event_id: event.id, bib_number: 11, split_id: 101, bitkey: 1) }
  let(:live_time_4) { build_stubbed(:live_time, event_id: event.id, bib_number: 11, split_id: 101, bitkey: 64) }
  let(:live_time_5) { build_stubbed(:live_time, event_id: event.id, bib_number: 10, split_id: 102, bitkey: 1) }
  let(:live_time_6) { build_stubbed(:live_time, event_id: event.id, bib_number: 10, split_id: 102, bitkey: 64) }
  let(:live_time_7) { build_stubbed(:live_time, event_id: event.id, bib_number: 10, split_id: 101, bitkey: 64) }
  let(:live_time_bad_split) { build_stubbed(:live_time, event_id: event.id, bib_number: 10, split_id: 999, bitkey: 1) }

  let(:live_entry_attributes) { [{title: 'Start',
                                  entries: [{split_id: 100, sub_split_kind: 'in', label: 'Start'}]},
                                 {title: 'Cunningham',
                                  entries: [{split_id: 101, sub_split_kind: 'in', label: 'Cunningham In'},
                                            {split_id: 101, sub_split_kind: 'out', label: 'Cunningham Out'}]},
                                 {title: 'Maggie',
                                  entries: [{split_id: 102, sub_split_kind: 'in', label: 'Maggie In'},
                                            {split_id: 102, sub_split_kind: 'out', label: 'Maggie Out'}]}] }

  describe '#pair' do
    context 'when all live_times can be paired' do
      let(:live_times) { [live_time_1, live_time_2, live_time_3, live_time_4, live_time_5, live_time_6, live_time_7] }

      it 'returns an array of paired live_time arrays' do
        allow(event).to receive(:live_entry_attributes).and_return(live_entry_attributes)
        expected = [[live_time_1, live_time_2], [nil, live_time_7], [live_time_3, live_time_4], [live_time_5, live_time_6]]
        expect(subject.pair).to eq(expected)
      end
    end

    context 'when any live_time contains an invalid split_id' do
      let(:live_times) { [live_time_bad_split] }

      it 'returns an array of paired live_time arrays' do
        expect { subject }.to raise_error(/All live_times must match the splits available/)
      end
    end
  end
end
