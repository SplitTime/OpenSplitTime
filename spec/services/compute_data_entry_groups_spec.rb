require 'rails_helper'

RSpec.describe ComputeDataEntryGroups do
  let(:distance_threshold) { Split::DISTANCE_THRESHOLD }

  describe '#perform' do
    subject { ComputeDataEntryGroups.new(event_group, pair_by_location: pair_by_location) }
    let(:pair_by_location) { true }

    let(:event_group) { build_stubbed(:event_group, events: [event_1, event_2]) }
    let(:event_1) { build_stubbed(:event, splits: event_1_splits, aid_stations: event_1_aid_stations) }
    let(:event_2) { build_stubbed(:event, splits: event_2_splits, aid_stations: event_2_aid_stations) }

    let(:event_1_split_1) { build_stubbed(:start_split, base_name: 'Start', latitude: 40, longitude: -105) }
    let(:event_1_split_2) { build_stubbed(:split, base_name: 'Aid 1', latitude: 41, longitude: -106) }
    let(:event_1_split_3) { build_stubbed(:split, base_name: 'Aid 2', latitude: 40.5, longitude: -105.5) }
    let(:event_1_split_4) { build_stubbed(:finish_split, base_name: 'Finish', latitude: 40, longitude: -105) }

    let(:event_1_aid_1) { build_stubbed(:aid_station, split: event_1_split_1) }
    let(:event_1_aid_2) { build_stubbed(:aid_station, split: event_1_split_2) }
    let(:event_1_aid_3) { build_stubbed(:aid_station, split: event_1_split_3) }
    let(:event_1_aid_4) { build_stubbed(:aid_station, split: event_1_split_4) }

    let(:event_2_split_1) { build_stubbed(:start_split, base_name: 'Start', latitude: 40, longitude: -105) }
    let(:event_2_split_2) { build_stubbed(:split, base_name: 'Aid 2', latitude: 40.5, longitude: -105.5) }
    let(:event_2_split_3) { build_stubbed(:finish_split, base_name: 'Finish', latitude: 40, longitude: -105) }

    let(:event_2_aid_1) { build_stubbed(:aid_station, split: event_2_split_1) }
    let(:event_2_aid_2) { build_stubbed(:aid_station, split: event_2_split_2) }
    let(:event_2_aid_3) { build_stubbed(:aid_station, split: event_2_split_3) }

    let(:event_1_splits) { [event_1_split_1, event_1_split_2, event_1_split_3, event_1_split_4] }
    let(:event_2_splits) { [event_2_split_1, event_2_split_2, event_2_split_3] }

    let(:event_1_aid_stations) { [event_1_aid_1, event_1_aid_2, event_1_aid_3, event_1_aid_4] }
    let(:event_2_aid_stations) { [event_2_aid_1, event_2_aid_2, event_2_aid_3] }


    context 'when start and finish are at the same location' do
      it 'returns a Struct having a title and data_entry_nodes with start and finish combined' do
        data_entry_groups = subject.perform
        expect(data_entry_groups.size).to eq(3)
        expect(data_entry_groups.map(&:title)).to eq(['Start/Finish', 'Aid 1', 'Aid 2'])
        expect(data_entry_groups.first.data_entry_nodes.size).to eq(2)
        expect(data_entry_groups.first.data_entry_nodes.map(&:split_name)).to eq(%w(start finish))
        expect(data_entry_groups.first.data_entry_nodes.map(&:sub_split_kind)).to eq(%w(in in))
        expect(data_entry_groups.first.data_entry_nodes.map(&:label)).to eq(%w(Start Finish))
      end
    end

    context 'when start and finish are at the same location but pair_by_location is false' do
      let(:pair_by_location) { false }

      it 'returns a Struct having a title and data_entry_nodes with start and finish separated' do
        data_entry_groups = subject.perform
        expect(data_entry_groups.size).to eq(4)
        expect(data_entry_groups.map(&:title)).to eq(['Start', 'Aid 1', 'Aid 2', 'Finish'])
        expect(data_entry_groups.first.data_entry_nodes.size).to eq(1)
        expect(data_entry_groups.first.data_entry_nodes.map(&:split_name)).to eq(%w(start))
        expect(data_entry_groups.first.data_entry_nodes.map(&:sub_split_kind)).to eq(%w(in))
        expect(data_entry_groups.first.data_entry_nodes.map(&:label)).to eq(%w(Start))
      end
    end

    context 'when start and finish are at different locations' do
      let(:event_1_split_4) { build_stubbed(:finish_split, base_name: 'Finish', latitude: 41, longitude: -106) }
      let(:event_2_split_3) { build_stubbed(:finish_split, base_name: 'Finish', latitude: 41, longitude: -106) }

      it 'returns a Struct having a title and data_entry_nodes with start and finish separated' do
        data_entry_groups = subject.perform
        expect(data_entry_groups.size).to eq(4)
        expect(data_entry_groups.map(&:title)).to eq(['Start', 'Aid 1', 'Aid 2', 'Finish'])
        expect(data_entry_groups.first.data_entry_nodes.size).to eq(1)
        expect(data_entry_groups.first.data_entry_nodes.map(&:split_name)).to eq(%w(start))
        expect(data_entry_groups.first.data_entry_nodes.map(&:sub_split_kind)).to eq(%w(in))
        expect(data_entry_groups.first.data_entry_nodes.map(&:label)).to eq(%w(Start))
      end
    end

    context 'when start and finish have no location' do
      let(:event_1_split_1) { build_stubbed(:start_split, base_name: 'Start', latitude: nil, longitude: nil) }
      let(:event_2_split_1) { build_stubbed(:start_split, base_name: 'Start', latitude: nil, longitude: nil) }
      let(:event_1_split_4) { build_stubbed(:finish_split, base_name: 'Finish', latitude: nil, longitude: nil) }
      let(:event_2_split_3) { build_stubbed(:finish_split, base_name: 'Finish', latitude: nil, longitude: nil) }

      it 'returns a Struct having a title and data_entry_nodes with start and finish separated' do
        data_entry_groups = subject.perform
        expect(data_entry_groups.size).to eq(4)
        expect(data_entry_groups.map(&:title)).to eq(['Start', 'Aid 1', 'Aid 2', 'Finish'])
        expect(data_entry_groups.first.data_entry_nodes.size).to eq(1)
        expect(data_entry_groups.first.data_entry_nodes.map(&:split_name)).to eq(%w(start))
        expect(data_entry_groups.first.data_entry_nodes.map(&:sub_split_kind)).to eq(%w(in))
        expect(data_entry_groups.first.data_entry_nodes.map(&:label)).to eq(%w(Start))
      end
    end
  end
end
