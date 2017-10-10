RSpec.describe SplitBuilder, type: :model do
  describe 'splits' do
    it 'returns an empty array when the input hash is empty' do
      builder = SplitBuilder.new({})
      expect(builder.splits).to eq([])
    end

    it 'returns the correct number of splits' do
      header_map = {'Start' => 0, 'Mountain Town' => 3000, 'Alpine Lake' => 6000, 'Finish' => 10000}
      builder = SplitBuilder.new(header_map)
      splits = builder.splits
      expect(splits.count).to eq(4)
    end

    it 'returns splits with the correct distances from start' do
      header_map = {'Start' => 0, 'Mountain Town' => 3000, 'Alpine Lake' => 6000, 'Finish' => 10000}
      builder = SplitBuilder.new(header_map)
      splits = builder.splits
      expect(splits.first.distance_from_start).to eq(0)
      expect(splits.second.distance_from_start).to eq(3000)
      expect(splits.third.distance_from_start).to eq(6000)
      expect(splits.last.distance_from_start).to eq(10000)
    end

    it 'returns splits with the correct base names' do
      header_map = {'Start' => 0, 'Mountain Town' => 3000, 'Alpine Lake' => 6000, 'Finish' => 10000}
      builder = SplitBuilder.new(header_map)
      splits = builder.splits
      expect(splits.first.base_name).to eq('Start')
      expect(splits.second.base_name).to eq('Mountain Town')
      expect(splits.third.base_name).to eq('Alpine Lake')
      expect(splits.last.base_name).to eq('Finish')
    end

    it 'returns splits with the correct kinds' do
      header_map = {'Start' => 0, 'Mountain Town' => 3000, 'Alpine Lake' => 6000, 'Finish' => 10000}
      builder = SplitBuilder.new(header_map)
      splits = builder.splits
      expect(splits.first.kind).to eq('start')
      expect(splits.second.kind).to eq('intermediate')
      expect(splits.third.kind).to eq('intermediate')
      expect(splits.last.kind).to eq('finish')
    end

    it 'returns single-stop splits with the sub_split_bitmap representing in only' do
      header_map = {'Start' => 0, 'Mountain Town' => 3000, 'Alpine Lake' => 6000, 'Finish' => 10000}
      builder = SplitBuilder.new(header_map)
      splits = builder.splits
      expect(splits.first.sub_split_bitmap).to eq(SubSplit::IN_BITKEY)
      expect(splits.second.sub_split_bitmap).to eq(SubSplit::IN_BITKEY)
      expect(splits.third.sub_split_bitmap).to eq(SubSplit::IN_BITKEY)
      expect(splits.last.sub_split_bitmap).to eq(SubSplit::IN_BITKEY)
    end

    it 'correctly determines split count for splits with multiple sub_splits' do
      header_map = {'Start' => 0, 'River In' => 3000, 'River Out' => 3000,
                    'Alpine Lake In' => 6000, 'Alpine Lake Out' => 6000, 'Finish' => 10000}
      builder = SplitBuilder.new(header_map)
      splits = builder.splits
      expect(splits.count).to eq(4)
    end

    it 'correctly determines base names for splits with multiple sub_splits' do
      header_map = {'Start' => 0, 'River In' => 3000, 'River Out' => 3000,
                    'Alpine Lake In' => 6000, 'Alpine Lake Out' => 6000, 'Finish' => 10000}
      builder = SplitBuilder.new(header_map)
      splits = builder.splits
      expect(splits.second.base_name).to eq('River')
      expect(splits.third.base_name).to eq('Alpine Lake')
    end

    it 'correctly determines sub_split_bitmaps for splits with multiple sub_splits' do
      header_map = {'Start' => 0, 'River In' => 3000, 'River Out' => 3000,
                    'Alpine Lake In' => 6000, 'Alpine Lake Out' => 6000, 'Finish' => 10000}
      builder = SplitBuilder.new(header_map)
      splits = builder.splits
      expect(splits.first.sub_split_bitmap).to eq(SubSplit::IN_BITKEY)
      expect(splits.second.sub_split_bitmap).to eq(SubSplit::IN_BITKEY | SubSplit::OUT_BITKEY)
      expect(splits.third.sub_split_bitmap).to eq(SubSplit::IN_BITKEY | SubSplit::OUT_BITKEY)
      expect(splits.last.sub_split_bitmap).to eq(SubSplit::IN_BITKEY)
    end
  end
end
