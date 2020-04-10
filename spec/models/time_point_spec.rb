# frozen_string_literal: true

RSpec.describe TimePoint, type: :model do
  require 'support/bitkey_definitions'
  include BitkeyDefinitions

  subject { TimePoint.new(lap, split_id, bitkey) }
  let(:lap) { 1 }
  let(:split_id) { 101 }
  let(:bitkey) { out_bitkey }

  describe 'initialization' do
    context 'with a split_id, a bitkey, and a lap' do
      it 'initializes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'with nil arguments' do
      let(:lap) { nil }
      let(:split_id) { nil }
      let(:bitkey) { nil }

      it 'initializes' do
        expect { subject }.not_to raise_error
      end
    end

    context 'with no arguments' do
      subject { TimePoint.new }

      it 'initializes' do
        expect { subject }.not_to raise_error
      end
    end
  end

  describe '#==' do
    let(:other) { TimePoint.new(other_lap, other_split_id, other_bitkey) }
    let(:other_lap) { lap }
    let(:other_split_id) { split_id }
    let(:other_bitkey) { bitkey }

    context 'when the other has identical lap, split_id, and bitkey' do
      it 'equates time_points' do
        expect(subject == other).to eq(true)
      end
    end

    context 'when laps are different' do
      let(:other_lap) { lap + 1 }

      it 'does not equate time_points' do
        expect(subject == other).to eq(false)
      end
    end


    context 'when split_ids are different' do
      let(:other_split_id) { split_id + 1 }

      it 'does not equate time_points' do
        expect(subject == other).to eq(false)
      end
    end

    context 'when bitkeys are different' do
      let(:other_bitkey) { in_bitkey }

      it 'does not equate time_points' do
        expect(subject == other).to eq(false)
      end
    end
  end

  describe '#lap' do
    it 'returns the first value passed to the TimePoint at initialization' do
      lap = 1
      split_id = 101
      bitkey = out_bitkey
      time_point = TimePoint.new(lap, split_id, bitkey)
      expect(time_point.lap).to eq(lap)
    end

    it 'returns nil if no value is given at initialization' do
      time_point = TimePoint.new
      expect(time_point.lap).to be_nil
    end
  end

  describe '#split_id' do
    it 'returns the second value passed to the TimePoint at initialization' do
      lap = 1
      split_id = 101
      bitkey = out_bitkey
      time_point = TimePoint.new(lap, split_id, bitkey)
      expect(time_point.split_id).to eq(split_id)
    end

    it 'returns nil if no value is given at initialization' do
      time_point = TimePoint.new
      expect(time_point.split_id).to be_nil
    end
  end

  describe '#bitkey' do
    it 'returns the third value passed to the TimePoint at initialization' do
      lap = 1
      split_id = 101
      bitkey = out_bitkey
      time_point = TimePoint.new(lap, split_id, bitkey)
      expect(time_point.bitkey).to eq(bitkey)
    end

    it 'returns nil if no value is given at initialization' do
      time_point = TimePoint.new
      expect(time_point.bitkey).to be_nil
    end
  end

  describe '#sub_split' do
    subject { TimePoint.new(lap, split_id, bitkey) }

    it 'returns a SubSplit using split_id and bitkey' do
      lap = 1
      split_id = 101
      bitkey = out_bitkey
      expect(subject.sub_split).to eq(SubSplit.new(split_id, bitkey))
    end

    it 'returns a SubSplit if bitkey is not present' do
      lap = 1
      split_id = 101
      expect(subject.sub_split).to eq(SubSplit.new(split_id, bitkey))
    end

    it 'returns a SubSplit if split_id is not present' do
      lap = 1
      bitkey = out_bitkey
      expect(subject.sub_split).to eq(SubSplit.new(split_id, bitkey))
    end
  end

  describe '#lap_split_key' do
    it 'returns a lap_split_key using lap and split_id' do
      lap = 1
      split_id = 101
      bitkey = out_bitkey
      time_point = TimePoint.new(lap, split_id, bitkey)
      expect(time_point.lap_split_key).to eq(LapSplitKey.new(lap, split_id))
    end

    it 'returns nil if lap is not present' do
      lap = nil
      split_id = 101
      bitkey = out_bitkey
      time_point = TimePoint.new(lap, split_id, bitkey)
      expect(time_point.lap_split_key).to be_nil
    end

    it 'returns nil if split_id is not present' do
      lap = 1
      split_id = nil
      bitkey = out_bitkey
      time_point = TimePoint.new(lap, split_id, bitkey)
      expect(time_point.lap_split_key).to be_nil
    end
  end

  describe '#kind' do
    it 'returns "In" or "Out" based on bitkey' do
      lap = 1
      split_id = 101
      bitkey = out_bitkey
      time_point = TimePoint.new(lap, split_id, bitkey)
      expect(time_point.kind).to eq('Out')
      time_point.bitkey = 1
      expect(time_point.kind).to eq('In')
    end

    it 'returns nil if bitkey is not present' do
      lap = 1
      split_id = 101
      bitkey = nil
      time_point = TimePoint.new(lap, split_id, bitkey)
      expect(time_point.kind).to be_nil
    end
  end

  describe '#in_sub_split?' do
    it 'returns true only if kind is "In"' do
      lap = 1
      split_id = 101
      bitkey = out_bitkey
      time_point = TimePoint.new(lap, split_id, bitkey)
      expect(time_point.in_sub_split?).to eq(false)
      time_point.bitkey = 1
      expect(time_point.in_sub_split?).to eq(true)
    end

    it 'returns false if bitkey is not present' do
      lap = 1
      split_id = 101
      bitkey = nil
      time_point = TimePoint.new(lap, split_id, bitkey)
      expect(time_point.in_sub_split?).to eq(false)
    end
  end

  describe '#out_sub_split?' do
    it 'returns true only if kind is "Out"' do
      lap = 1
      split_id = 101
      bitkey = out_bitkey
      time_point = TimePoint.new(lap, split_id, bitkey)
      expect(time_point.out_sub_split?).to eq(true)
      time_point.bitkey = 1
      expect(time_point.out_sub_split?).to eq(false)
    end

    it 'returns false if bitkey is not present' do
      lap = 1
      split_id = 101
      bitkey = nil
      time_point = TimePoint.new(lap, split_id, bitkey)
      expect(time_point.out_sub_split?).to eq(false)
    end
  end
end
