# frozen_string_literal: true

RSpec.describe DataEntryGroup do
  subject { DataEntryGroup.new(data_entry_nodes) }
  let(:data_entry_nodes) { [node_1, node_2] }

  describe '#min_distance_from_start' do
    let(:node_1) { DataEntryNode.new(min_distance_from_start: 2000) }
    let(:node_2) { DataEntryNode.new(min_distance_from_start: 3000) }

    it 'returns the minimum distance' do
      expect(subject.min_distance_from_start).to eq(2000)
    end
  end

  describe '#split_names' do
    context 'when all nodes have the same split_name' do
      let(:node_1) { DataEntryNode.new(split_name: 'Aid Station 1') }
      let(:node_2) { DataEntryNode.new(split_name: 'Aid Station 1') }

      it 'returns an array of the split names' do
        expect(subject.split_names).to eq(['Aid Station 1', 'Aid Station 1'])
      end
    end

    context 'when nodes have different split_names' do
      let(:node_1) { DataEntryNode.new(split_name: 'Start') }
      let(:node_2) { DataEntryNode.new(split_name: 'Finish') }

      it 'returns an array of the split_names' do
        expect(subject.split_names).to eq(%w(Start Finish))
      end
    end
  end

  describe '#title' do
    context 'when all nodes have the same split_name' do
      let(:node_1) { DataEntryNode.new(split_name: 'Aid Station 1') }
      let(:node_2) { DataEntryNode.new(split_name: 'Aid Station 1') }

      it 'returns the split_name' do
        expect(subject.title).to eq('Aid Station 1')
      end
    end

    context 'when nodes have different split_names' do
      let(:node_1) { DataEntryNode.new(split_name: 'Start') }
      let(:node_2) { DataEntryNode.new(split_name: 'Finish') }

      it 'returns the combined split_names' do
        expect(subject.title).to eq('Start/Finish')
      end
    end

    context 'when nodes have similar split_names with differences in capitalization' do
      let(:node_1) { DataEntryNode.new(split_name: 'AID STATION 1') }
      let(:node_2) { DataEntryNode.new(split_name: 'Aid Station 1') }

      it 'returns a single split_name with the capitalization of the first node' do
        expect(subject.title).to eq('AID STATION 1')
      end
    end

    context 'when nodes have similar split_names with differences in punctuation' do
      let(:node_1) { DataEntryNode.new(split_name: 'Aid-Station(1)') }
      let(:node_2) { DataEntryNode.new(split_name: 'Aid Station 1') }

      it 'returns a single split_name with the punctuation of the first node' do
        expect(subject.title).to eq('Aid-Station(1)')
      end
    end
  end
end
