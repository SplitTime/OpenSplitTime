require 'rails_helper'

RSpec.describe EventGroupSplitAnalyzer do
  subject { EventGroupSplitAnalyzer.new(event_group) }

  let(:event_1) { build_stubbed(:event, splits: event_1_splits, aid_stations: event_1_aid_stations) }
  let(:event_2) { build_stubbed(:event, splits: event_2_splits, aid_stations: event_2_aid_stations) }
  let(:event_3) { build_stubbed(:event, splits: event_3_splits, aid_stations: event_3_aid_stations) }

  let(:event_1_split_1) { build_stubbed(:start_split, base_name: 'Start') }
  let(:event_1_split_2) { build_stubbed(:split, base_name: 'Aid 1') }
  let(:event_1_split_3) { build_stubbed(:split, base_name: 'Aid 2') }
  let(:event_1_split_4) { build_stubbed(:finish_split, base_name: 'Finish') }

  let(:event_1_aid_1) { build_stubbed(:aid_station, split: event_1_split_1) }
  let(:event_1_aid_2) { build_stubbed(:aid_station, split: event_1_split_2) }
  let(:event_1_aid_3) { build_stubbed(:aid_station, split: event_1_split_3) }
  let(:event_1_aid_4) { build_stubbed(:aid_station, split: event_1_split_4) }

  let(:event_2_split_1) { build_stubbed(:start_split, base_name: 'Start') }
  let(:event_2_split_2) { build_stubbed(:split, base_name: 'Aid 2') }
  let(:event_2_split_3) { build_stubbed(:finish_split, base_name: 'Finish') }

  let(:event_2_aid_1) { build_stubbed(:aid_station, split: event_2_split_1) }
  let(:event_2_aid_2) { build_stubbed(:aid_station, split: event_2_split_2) }
  let(:event_2_aid_3) { build_stubbed(:aid_station, split: event_2_split_3) }

  let(:event_3_split_1) { build_stubbed(:start_split, base_name: 'Start') }
  let(:event_3_split_2) { build_stubbed(:split, base_name: 'Aid 2', sub_split_bitmap: 1) }
  let(:event_3_split_3) { build_stubbed(:finish_split, base_name: 'Finish') }

  let(:event_3_aid_1) { build_stubbed(:aid_station, split: event_3_split_1) }
  let(:event_3_aid_2) { build_stubbed(:aid_station, split: event_3_split_2) }
  let(:event_3_aid_3) { build_stubbed(:aid_station, split: event_3_split_3) }

  let(:event_1_splits) { [event_1_split_1, event_1_split_2, event_1_split_3, event_1_split_4] }
  let(:event_2_splits) { [event_2_split_1, event_2_split_2, event_2_split_3] }
  let(:event_3_splits) { [event_3_split_1, event_3_split_2, event_3_split_3] }

  let(:event_1_aid_stations) { [event_1_aid_1, event_1_aid_2, event_1_aid_3, event_1_aid_4] }
  let(:event_2_aid_stations) { [event_2_aid_1, event_2_aid_2, event_2_aid_3] }
  let(:event_3_aid_stations) { [event_3_aid_1, event_3_aid_2, event_3_aid_3] }


  describe '#splits_by_event' do
    context 'when splits with matching names are found' do
      let(:event_group) { build_stubbed(:event_group, events: [event_1, event_2]) }
      let(:split_name) { 'aid-2' }
      let(:expected) { {event_1.id => event_1_split_3, event_2.id => event_2_split_2} }

      it 'returns a hash with matching splits and aid_stations grouped together' do
        expect(subject.splits_by_event(split_name)).to eq(expected)
      end
    end
  end

  describe '#aid_stations_by_event' do
    context 'when splits with matching names are found' do
      let(:event_group) { build_stubbed(:event_group, events: [event_1, event_2]) }
      let(:split_name) { 'aid-2' }
      let(:expected) { {event_1.id => event_1_aid_3, event_2.id => event_2_aid_2} }

      it 'returns a hash with matching splits and aid_stations grouped together' do
        expect(subject.aid_stations_by_event(split_name)).to eq(expected)
      end
    end
  end

  describe '#ordered_split_names' do
    let(:event_group) { build_stubbed(:event_group, events: [event_1, event_2]) }
    let(:expected) { %w(start aid-1 aid-2 finish) }

    it 'returns a non-duplicative list of split_names from the event_group' do
      expect(subject.ordered_split_names).to eq(expected)
    end
  end

  describe '#incompatible_splits' do
    context 'when splits with matching names have no location' do
      let(:event_group) { build_stubbed(:event_group, events: [event_1, event_2]) }
      let(:split_name) { 'aid-2' }

      it 'returns an empty array' do
        expect(subject.incompatible_locations).to be_empty
      end
    end

    context 'when splits with matching names are too far apart in location' do
      let(:event_group) { build_stubbed(:event_group, events: [event_1, event_2]) }
      let(:split_name) { 'aid-2' }
      before do
        event_1_split_3.assign_attributes(latitude: 40, longitude: -105)
        event_2_split_2.assign_attributes(latitude: 41, longitude: -106)
      end

      it 'includes the split_name' do
        expect(subject.incompatible_locations).to include(split_name)
      end
    end
  end
end
