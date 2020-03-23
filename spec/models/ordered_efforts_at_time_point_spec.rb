# frozen_string_literal: true

RSpec.describe OrderedEffortsAtTimePoint do
  subject { described_class.new(lap: lap, split_id: split_id, sub_split_bitkey: sub_split_bitkey, effort_ids: effort_ids) }
  let(:lap) { 1 }
  let(:split_id) { 101 }
  let(:sub_split_bitkey) { SubSplit::IN_BITKEY }

  context 'when given a Postgres-style array' do
    let(:effort_ids) { '{1001,1003,1005}' }
    it 'casts effort_ids as an array' do
      expect(subject.effort_ids).to eq([1001, 1003, 1005])
    end
  end

  context 'when given an empty Postgres-style array' do
    let(:effort_ids) { '{}' }
    it 'casts as an empty array' do
      expect(subject.effort_ids).to eq([])
    end
  end

  context 'when given an empty string' do
    let(:effort_ids) { '' }
    it 'casts as an empty array' do
      expect(subject.effort_ids).to eq([])
    end
  end
end
