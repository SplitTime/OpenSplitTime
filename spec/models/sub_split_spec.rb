require 'rails_helper'

RSpec.describe SubSplit, type: :model do

  describe 'kind' do

    it 'should return "In" when passed 1 or IN_BITKEY' do
      expect(SubSplit.kind(1)).to eq('In')
      expect(SubSplit.kind(SubSplit::IN_BITKEY)).to eq('In')
    end

    it 'should return "Out" when passed 64 or OUT_BITKEY' do
      expect(SubSplit.kind(64)).to eq('Out')
      expect(SubSplit.kind(SubSplit::OUT_BITKEY)).to eq('Out')
    end

    it 'should return nil given any other parameter' do
      expect(SubSplit.kind(8)).to eq(nil)
      expect(SubSplit.kind(50)).to eq(nil)
    end

  end

  describe 'kinds' do

    it 'should return an array of all existing kinds' do
      expect(SubSplit.kinds).to eq(%w(In Out))
    end

  end

  describe 'bitkey' do

    it 'should return IN_BITKEY when passed "In"' do
      expect(SubSplit.bitkey('In')).to eq(SubSplit::IN_BITKEY)
    end

    it 'should return OUT_BITKEY when passed "Out"' do
      expect(SubSplit.bitkey('Out')).to eq(SubSplit::OUT_BITKEY)
    end

    it 'should return nil given any other parameter' do
      expect(SubSplit.bitkey('Big')).to eq(nil)
      expect(SubSplit.bitkey(nil)).to eq(nil)
    end

  end

  describe 'bitkeys' do

    it 'should return an array of all existing bitkeys' do
      expect(SubSplit.bitkeys).to eq([1, 64])
    end

  end

  describe 'next_bitkey' do

    it 'should return the next leftmost "on" bit with 1' do
      expect(SubSplit.next_bitkey(1)).to eq(SubSplit::OUT_BITKEY)
    end

    it 'should return the next leftmost "on" bit with 4' do
      expect(SubSplit.next_bitkey(4)).to eq(SubSplit::OUT_BITKEY)
    end

    it 'should return nil with 64' do
      expect(SubSplit.next_bitkey(64)).to eq(nil)
    end

  end

  describe 'reveal_valid_bitkeys' do

    it 'should return an array of valid bitkeys when passed a bitmap' do
      expect(SubSplit.reveal_valid_bitkeys(1)).to eq([1])
      expect(SubSplit.reveal_valid_bitkeys(65)).to eq([1, 64])
      expect(SubSplit.reveal_valid_bitkeys(127)).to eq([1, 64])
      expect(SubSplit.reveal_valid_bitkeys(8)).to eq([])
      expect(SubSplit.reveal_valid_bitkeys(0)).to eq([])
    end

  end

end