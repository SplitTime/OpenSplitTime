# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventGroupSplitAnalyzer do
  subject { EventGroupSplitAnalyzer.new(event_group) }

  let(:event_group) { event_groups(:sum) }
  let(:event_1) { events(:sum_100k) }
  let(:event_2) { events(:sum_55k) }
  let(:event_1_molas) { event_1.ordered_splits.second }
  let(:event_2_molas) { event_2.ordered_splits.second }

  describe '#splits_by_event' do
    context 'when splits with matching names are found' do
      let(:split_name) { 'molas-pass-aid1' }
      let(:expected) { {event_1.id => event_1_molas, event_2.id => event_2_molas} }

      it 'returns a hash with matching splits and aid_stations grouped together' do
        expect(subject.splits_by_event(split_name)).to eq(expected)
      end
    end

    context 'when splits with matching names are not found' do
      let(:split_name) { 'non-existent' }
      let(:expected) { {} }

      it 'returns an empty hash' do
        expect(subject.splits_by_event(split_name)).to eq(expected)
      end
    end
  end

  describe '#aid_stations_by_event' do
    context 'when splits with matching names are found' do
      let(:split_name) { 'molas-pass-aid1' }
      let(:expected) { {event_1.id => event_1.ordered_aid_stations.second, event_2.id => event_2.ordered_aid_stations.second} }

      it 'returns a hash with matching splits and aid_stations grouped together' do
        expect(subject.aid_stations_by_event(split_name)).to eq(expected)
      end
    end

    context 'when splits with matching names are not found' do
      let(:split_name) { 'non-existent' }
      let(:expected) { {} }

      it 'returns an empty hash' do
        expect(subject.aid_stations_by_event(split_name)).to eq(expected)
      end
    end
  end

  describe '#ordered_split_names' do
    let(:expected) { ['Start', 'Molas Pass (Aid1)', 'Rolling Pass (Aid2)', 'Cascade Creek Rd (Aid3)',
                      'Engineer Mtn TH (Aid4)', 'Bandera Mine (Aid5)', 'Anvil CG (Aid6)', 'Finish'] }

    it 'returns a non-duplicative, ordered list of split_names from the event_group' do
      expect(subject.ordered_split_names).to eq(expected)
    end
  end

  describe '#parameterized_split_names' do
    let(:expected) { %w(start molas-pass-aid1 rolling-pass-aid2 cascade-creek-rd-aid3 engineer-mtn-th-aid4 bandera-mine-aid5 anvil-cg-aid6 finish) }

    it 'returns a non-duplicative, ordered list of parameterized split_names from the event_group' do
      expect(subject.parameterized_split_names).to eq(expected)
    end
  end

  describe '#incompatible_splits' do
    context 'when splits with matching names have no location' do
      it 'returns an empty array' do
        expect(subject.incompatible_locations).to be_empty
      end
    end

    context 'when splits with matching names are too far apart in location' do
      let(:event_group) { build_stubbed(:event_group, events: [event_1, event_2]) }
      let(:split_name) { 'molas-pass-aid1' }

      before do
        event_1_molas.assign_attributes(latitude: 40, longitude: -105)
        event_2_molas.assign_attributes(latitude: 41, longitude: -106)
      end

      it 'includes the parameterized split name' do
        expect(subject.incompatible_locations).to include(split_name)
      end
    end
  end
end
