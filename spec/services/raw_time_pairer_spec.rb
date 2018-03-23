require 'rails_helper'

RSpec.describe RawTimePairer do
  subject { RawTimePairer.new(event_group: event_group, raw_times: raw_times) }
  let(:event_group) { build_stubbed(:event_group) }
  let(:event_1) { build_stubbed(:event, event_group: event_group) }
  let(:event_2) { build_stubbed(:event, event_group: event_group) }
  let(:raw_time_1) { build_stubbed(:raw_time, event_group_id: event_group.id, bib_number: '10', split_name: 'cunningham', bitkey: 1, stopped_here: false) }
  let(:raw_time_2) { build_stubbed(:raw_time, event_group_id: event_group.id, bib_number: '10', split_name: 'cunningham', bitkey: 64, stopped_here: true) }
  let(:raw_time_3) { build_stubbed(:raw_time, event_group_id: event_group.id, bib_number: '11', split_name: 'cunningham', bitkey: 1, with_pacer: true) }
  let(:raw_time_4) { build_stubbed(:raw_time, event_group_id: event_group.id, bib_number: '11', split_name: 'cunningham', bitkey: 64, with_pacer: true) }
  let(:raw_time_5) { build_stubbed(:raw_time, event_group_id: event_group.id, bib_number: '10', split_name: 'maggie', bitkey: 1) }
  let(:raw_time_6) { build_stubbed(:raw_time, event_group_id: event_group.id, bib_number: '10', split_name: 'maggie', bitkey: 64) }
  let(:raw_time_7) { build_stubbed(:raw_time, event_group_id: event_group.id, bib_number: '10', split_name: 'cunningham', bitkey: 64) }
  let(:raw_time_bad_split) { build_stubbed(:raw_time, event_group_id: event_group.id, bib_number: '10', split_name: 'bad-split', bitkey: 1) }
  let(:raw_time_wildcard_1) { build_stubbed(:raw_time, event_group_id: event_group.id, bib_number: '10*', split_name: 'cunningham', bitkey: 1) }
  let(:raw_time_wildcard_2) { build_stubbed(:raw_time, event_group_id: event_group.id, bib_number: '10*', split_name: 'cunningham', bitkey: 64) }

  let(:data_entry_groups) { [DataEntryGroup.new([start_node]),
                             DataEntryGroup.new([cunningham_node_in, cunningham_node_out]),
                             DataEntryGroup.new([maggie_node_in, maggie_node_out])] }
  let(:start_node) { DataEntryNode.new(split_name: 'start', sub_split_kind: 'in', label: 'Start', min_distance_from_start: 0,
                                       event_split_ids: {event_1.id => 101, event_2.id => 201},
                                       event_aid_station_ids: {}) }
  let(:cunningham_node_in) { DataEntryNode.new(split_name: 'cunningham', sub_split_kind: 'in', label: 'Cunningham In', min_distance_from_start: 14966,
                                               event_split_ids: {event_1.id => 102, event_2.id => 202},
                                               event_aid_station_ids: {}) }
  let(:cunningham_node_out) { DataEntryNode.new(split_name: 'cunningham', sub_split_kind: 'out', label: 'Cunningham Out', min_distance_from_start: 14966,
                                                event_split_ids: {event_1.id => 102, event_2.id => 202},
                                                event_aid_station_ids: {}) }
  let(:maggie_node_in) { DataEntryNode.new(split_name: 'maggie', sub_split_kind: 'in', label: 'Maggie In', min_distance_from_start: 14966,
                                           event_split_ids: {event_1.id => 103, event_2.id => 203},
                                           event_aid_station_ids: {}) }
  let(:maggie_node_out) { DataEntryNode.new(split_name: 'maggie', sub_split_kind: 'out', label: 'Maggie Out', min_distance_from_start: 14966,
                                            event_split_ids: {event_1.id => 103, event_2.id => 203},
                                            event_aid_station_ids: {}) }

  before { allow_any_instance_of(RawTimePairer).to receive(:data_entry_groups).and_return(data_entry_groups) }

  describe '#pair' do
    context 'when all raw_times can be paired' do
      let(:raw_times) { [raw_time_1, raw_time_2, raw_time_3, raw_time_4, raw_time_5, raw_time_6, raw_time_7] }

      it 'returns an array of paired raw_time arrays' do
        expected = [[raw_time_1, raw_time_2], [nil, raw_time_7], [raw_time_3, raw_time_4], [raw_time_5, raw_time_6]]
        expect(subject.pair).to eq(expected)
      end

      it 'retains boolean attributes' do
        expect(subject.pair.first.map(&:stopped_here)).to eq([false, true])
        expect(subject.pair.third.map(&:with_pacer)).to eq([true, true])
      end
    end

    context 'when any raw_time contains an invalid split_name' do
      let(:raw_times) { [raw_time_bad_split] }

      it 'returns an array of paired raw_time arrays' do
        expect { subject }.to raise_error(/All raw_times must match the split_names available in data_entry_groups/)
      end
    end

    context 'when raw_times contain wildcard characters' do
      let(:raw_times) { [raw_time_1, raw_time_2, raw_time_wildcard_1, raw_time_wildcard_2] }

      it 'pairs matching wildcard bib_numbers with each other but not with any other raw_time' do
        expected = [[raw_time_1, raw_time_2], [raw_time_wildcard_1, raw_time_wildcard_2]]
        expect(subject.pair).to eq(expected)
      end
    end
  end
end
