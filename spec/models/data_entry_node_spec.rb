# frozen_string_literal: true

require 'support/concerns/locatable'

RSpec.describe DataEntryNode do
  it_behaves_like 'locatable'

  subject { DataEntryNode.new(attributes) }

  let(:attributes) { {split_name: 'Split Name',
                      parameterized_split_name: 'split-name',
                      display_split_name: 'Split Name',
                      sub_split_kind: 'in',
                      label: 'label',
                      latitude: 40,
                      longitude: -105,
                      min_distance_from_start: 0,
                      event_split_ids: {1 => 1, 2 => 2},
                      event_aid_station_ids: {3 => 3, 4 => 4}} }

  describe '#to_h' do
    it 'returns all attributes in a Hash' do
      expect(subject.to_h).to eq(attributes)
    end
  end

  describe '#split_name' do
    it 'returns the split_name' do
      expect(subject.split_name).to eq('Split Name')
    end
  end
end
