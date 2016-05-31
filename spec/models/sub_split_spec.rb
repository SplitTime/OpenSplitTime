require 'rails_helper'

# t.integer "key",       null: false
# t.string  "kind",       null: false


RSpec.describe SubSplit, type: :model do

  describe 'kind' do

    it 'should return "In" when passed 1 or IN_KEY' do
      expect(SubSplit.kind(1)).to eq('In')
      expect(SubSplit.kind(SubSplit::IN_KEY)).to eq('In')
    end

    it 'should return "Out" when passed 64 or OUT_KEY' do
      expect(SubSplit.kind(64)).to eq('Out')
      expect(SubSplit.kind(SubSplit::OUT_KEY)).to eq('Out')
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

  describe 'key' do

    it 'should return IN_KEY when passed "In"' do
      expect(SubSplit.key('In')).to eq(SubSplit::IN_KEY)
    end

    it 'should return OUT_KEY when passed "Out"' do
      expect(SubSplit.key('Out')).to eq(SubSplit::OUT_KEY)
    end

    it 'should return nil given any other parameter' do
      expect(SubSplit.key('Big')).to eq(nil)
      expect(SubSplit.key(nil)).to eq(nil)
    end

  end

  describe 'keys' do

    it 'should return an array of all existing keys' do
      expect(SubSplit.keys).to eq([1, 64])
    end

  end

  describe 'next_key' do

    it 'should return the next leftmost "on" bit with 1' do
      expect(SubSplit.next_key(1)).to eq(SubSplit::OUT_KEY)
    end

    it 'should return the next leftmost "on" bit with 4' do
      expect(SubSplit.next_key(4)).to eq(SubSplit::OUT_KEY)
    end

    it 'should return nil with 64' do
      expect(SubSplit.next_key(64)).to eq(nil)
    end

  end

  describe 'reveal_valid_keys' do

    it 'should return an array of valid keys when passed a mask' do
      expect(SubSplit.reveal_valid_keys(1)).to eq([1])
      expect(SubSplit.reveal_valid_keys(65)).to eq([1, 64])
      expect(SubSplit.reveal_valid_keys(127)).to eq([1, 64])
      expect(SubSplit.reveal_valid_keys(8)).to eq([])
      expect(SubSplit.reveal_valid_keys(0)).to eq([])
    end

  end

end