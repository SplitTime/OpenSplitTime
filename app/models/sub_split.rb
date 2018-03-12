# frozen_string_literal: true

# This class replaces the former ActiveRecord class of the same name.
# A 'bitkey' is an integer representing a single bit.
# A 'bitmap' is an integer representing a combination of bitkeys.
# Each instance of SplitTime includes a bitkey indicating the type of time record it represents.
# Each instance of Split includes a bitmap indicating all valid split_times that may relate to the split.
# For example, the sub_split_bitmap for a start or finish split would be 1,
# representing a single time recorded at that point, while the sub_split_bitmap
# for a split having 'in' and 'out' times would be 65, representing a
# bitkey of 1 for the 'in' time and a bitkey of 64 for the 'out' time.

class SubSplit

  # To add a new SubSplit kind, define its constant here
  # For example, 'CHANGE_BITKEY = 8'
  # Then add it to the aggregate bitmap
  # For example, 'IN_BITKEY | CHANGE_BITKEY | OUT_BITKEY'
  # And add a new case to self.kind for its name
  # For example, 'when CHANGE_BITKEY; "Change"'
  # And add a new case to self.bitkey for its kind
  # For example, 'when 'change'; CHANGE_BITKEY

  IN_BITKEY = 1
  OUT_BITKEY = 64

  def self.aggregate_bitmap
    IN_BITKEY | OUT_BITKEY
  end

  def self.kind(bitkey)
    case bitkey
      when IN_BITKEY
        'In'
      when OUT_BITKEY
        'Out'
      else
        nil
    end
  end

  def self.kinds # Returns an array of all existing kinds
    reveal_bitkeys(aggregate_bitmap).map { |bitkey| kind(bitkey) }
  end

  def self.bitkey(kind)
    case kind.to_s.downcase
      when 'in'
        IN_BITKEY
      when 'out'
        OUT_BITKEY
      else
        nil
    end
  end

  def self.bitkeys # Returns an array of all existing bitkeys
    reveal_bitkeys(aggregate_bitmap)
  end

  def self.next_bitkey(bitkey)
    agg = aggregate_bitmap
    bitkey = bitkey << 1
    return nil if (bitkey > agg) || (bitkey < 1)
    while (bitkey & agg) == 0 do
      bitkey = bitkey << 1
    end
    bitkey
  end

  def self.reveal_valid_bitkeys(bitmap)
    reveal_bitkeys(validate_bitmap(bitmap))
  end

  def self.validate_bitmap(bitmap)
    bitmap & self.aggregate_bitmap
  end

  def self.reveal_bitkeys(bitmap)
    result = []
    (0...bitmap.to_s(2).size).each { |k| result << (bitmap & (1 << k)) }
    result.reject { |x| x == 0 }
  end
end