# This class replaces the former ActiveRecord class of the same name. 
# A 'key' is an integer representing a single bit. 
# A 'mask' is an integer representing a combination of keys.
# Each instance of SplitTime includes a key indicating the type of time record it represents.
# Each instance of Split includes a mask indicating all valid split_times that may relate to the split.
# For example, the sub_split_mask for a start or finish split would be 1, 
# representing a single time recorded at that point.

class SubSplit

  # To add a new SubSplit kind, define its constant here
  # For example, 'CHANGE_KEY = 8'
  # Then add it to the aggregate mask
  # For example, 'IN_KEY | CHANGE_KEY | OUT_KEY'
  # And add a new case to self.kind for its name
  # For example, 'when CHANGE_KEY; "Change"'

  IN_KEY = 1
  OUT_KEY = 64

  def self.aggregate_mask
    IN_KEY | OUT_KEY
  end

  def self.kind(key)
    case key
      when IN_KEY
        'In'
      when OUT_KEY
        'Out'
      else
        nil
    end
  end

  def self.kinds # Returns an array of all existing kinds
    reveal_keys(aggregate_mask).map { |key| kind(key) }
  end

  def self.key(kind)
    case kind.try(:downcase)
      when 'in'
        IN_KEY
      when 'out'
        OUT_KEY
      else
        nil
    end
  end

  def self.keys # Returns an array of all existing keys
    reveal_keys(aggregate_mask)
  end

  def self.next_key(key)
    agg = aggregate_mask
    key = key << 1
    return nil if (key > agg) || (key < 1)
    while (key & agg) == 0 do
      key = key << 1
    end
    key
  end

  def self.reveal_valid_keys(mask)
    reveal_keys(validate_mask(mask))
  end

  def self.validate_mask(mask)
    mask & self.aggregate_mask
  end

  def self.reveal_keys(mask)
    result = []
    (0...mask.to_s(2).size).each { |k| result << (mask & (1 << k)) }
    result.reject { |x| x == 0 }
  end

end