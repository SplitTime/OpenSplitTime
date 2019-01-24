# frozen_string_literal: true

RSpec.describe SubSplit, type: :model do
  require 'support/bitkey_definitions'
  include BitkeyDefinitions

  describe '#initialize' do
    subject { SubSplit.new(split_id, bitkey) }

    context 'when provided with a split_id and bitkey' do
      let(:split_id) { 101 }
      let(:bitkey) { in_bitkey }

      it 'initializes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when provided with neither a split_id nor bitkey' do
      let(:split_id) { nil }
      let(:bitkey) { nil }

      it 'initializes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when provided with no arguments' do
      subject { SubSplit.new }

      it 'initializes with nil values for split_id and bitkey' do
        expect { subject }.not_to raise_error
        expect(subject.split_id).to be_nil
        expect(subject.bitkey).to be_nil
      end
    end
  end

  describe '#split_id and #bitkey' do
    subject { SubSplit.new(split_id, bitkey) }

    context 'when attributes are present' do
      let(:split_id) { 101 }
      let(:bitkey) { in_bitkey }

      it 'returns the attributes' do
        expect(subject.split_id).to eq(split_id)
        expect(subject.bitkey).to eq(bitkey)
      end

      it 'returns the bitkey when asked for sub_split_bitkey' do
        expect(subject.sub_split_bitkey).to eq(bitkey)
      end
    end
  end

  describe '#==' do
    subject { SubSplit.new(split_id, bitkey) }
    let(:split_id) { 101 }
    let(:bitkey) { in_bitkey }
    let(:other) { SubSplit.new(other_split_id, other_bitkey) }

    context 'when the split_id and bitkey are the same' do
      let(:other_split_id) { 101 }
      let(:other_bitkey) { in_bitkey }

      it 'equates the two objects' do
        expect(subject == other).to eq(true)
      end
    end

    context 'when the split_id is different' do
      let(:other_split_id) { 102 }
      let(:other_bitkey) { in_bitkey }

      it 'does not equate the two objects' do
        expect(subject == other).to eq(false)
      end
    end

    context 'when the bitkey is different' do
      let(:other_split_id) { 101 }
      let(:other_bitkey) { out_bitkey }

      it 'does not equate the two objects' do
        expect(subject == other).to eq(false)
      end
    end

    context 'when the other is nil' do
      let(:other) { nil }

      it 'does not equate the two objects' do
        expect(other == subject).to eq(false)
        expect(subject == other).to eq(false)
      end
    end

    context 'when the other is not a SubSplit' do
      let(:other) { 'hello' }

      it 'does not equate the two objects' do
        expect(other == subject).to eq(false)
        expect(subject == other).to eq(false)
      end
    end
  end

  describe '.kind' do
    it 'returns "In" when passed 1 or IN_BITKEY' do
      expect(SubSplit.kind(1)).to eq('In')
      expect(SubSplit.kind(in_bitkey)).to eq('In')
    end

    it 'returns "Out" when passed 64 or OUT_BITKEY' do
      expect(SubSplit.kind(64)).to eq('Out')
      expect(SubSplit.kind(out_bitkey)).to eq('Out')
    end

    it 'returns nil given any other parameter' do
      expect(SubSplit.kind(8)).to eq(nil)
      expect(SubSplit.kind(50)).to eq(nil)
    end
  end

  describe '.kinds' do
    it 'returns an array of all existing kinds' do
      expect(SubSplit.kinds).to eq(%w(In Out))
    end
  end

  describe '.bitkey' do
    it 'returns IN_BITKEY when passed "In"' do
      expect(SubSplit.bitkey('In')).to eq(in_bitkey)
    end

    it 'returns OUT_BITKEY when passed "Out"' do
      expect(SubSplit.bitkey('Out')).to eq(out_bitkey)
    end

    it 'functions regardless of case' do
      expect(SubSplit.bitkey('in')).to eq(in_bitkey)
    end

    it 'functions when passed a symbol' do
      expect(SubSplit.bitkey(:in)).to eq(in_bitkey)
    end

    it 'returns nil given any other parameter' do
      expect(SubSplit.bitkey('Big')).to eq(nil)
      expect(SubSplit.bitkey(nil)).to eq(nil)
    end
  end

  describe '.bitkeys' do
    it 'returns an array of all existing bitkeys' do
      expect(SubSplit.bitkeys).to eq([1, 64])
    end
  end

  describe '.next_bitkey' do
    it 'returns the next leftmost "on" bit with 1' do
      expect(SubSplit.next_bitkey(1)).to eq(out_bitkey)
    end

    it 'returns the next leftmost "on" bit with 4' do
      expect(SubSplit.next_bitkey(4)).to eq(out_bitkey)
    end

    it 'returns nil with 64' do
      expect(SubSplit.next_bitkey(64)).to eq(nil)
    end
  end

  describe '.reveal_valid_bitkeys' do
    it 'returns an array of valid bitkeys when passed a bitmap' do
      expect(SubSplit.reveal_valid_bitkeys(1)).to eq([1])
      expect(SubSplit.reveal_valid_bitkeys(65)).to eq([1, 64])
      expect(SubSplit.reveal_valid_bitkeys(127)).to eq([1, 64])
      expect(SubSplit.reveal_valid_bitkeys(8)).to eq([])
      expect(SubSplit.reveal_valid_bitkeys(0)).to eq([])
    end
  end
end
