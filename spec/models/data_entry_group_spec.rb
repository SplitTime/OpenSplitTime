RSpec.describe DataEntryGroup do
  subject { DataEntryGroup.new(data_entry_nodes) }
  let(:data_entry_nodes) { [node_1, node_2] }

  describe '#title' do
    context 'when all nodes have the same split_name' do
      let(:node_1) { DataEntryNode.new(split_name: 'aid-station-1') }
      let(:node_2) { DataEntryNode.new(split_name: 'aid-station-1') }

      it 'returns a titleized version of the split_name' do
        expect(subject.title).to eq('Aid Station 1')
      end
    end

    context 'when nodes have different split_names' do
      let(:node_1) { DataEntryNode.new(split_name: 'start') }
      let(:node_2) { DataEntryNode.new(split_name: 'finish') }

      it 'returns a titleized version of the combined split_names' do
        expect(subject.title).to eq('Start/Finish')
      end
    end
  end

  describe '#min_distance_from_start' do
    let(:node_1) { DataEntryNode.new(min_distance_from_start: 2000) }
    let(:node_2) { DataEntryNode.new(min_distance_from_start: 3000) }

    it 'returns the minimum distance' do
      expect(subject.min_distance_from_start).to eq(2000)
    end
  end
end
