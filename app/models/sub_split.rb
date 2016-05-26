class SubSplit < ActiveRecord::Base

  has_many :split_times

  validates_presence_of :bitkey, :kind
  validates_uniqueness_of :bitkey
  validates_uniqueness_of :kind, case_sensitive: false
  validate :bitkey_bits_are_unique
  validate :bitkey_single_bit, unless: 'bitkey.nil?'

  self.primary_key = 'bitkey'

  # Methods for validations

  def self.aggregate_mask
    combined_mask = 0
    SubSplit.all.pluck(:bitkey).each do |bitkey|
      combined_mask |= bitkey
    end
    combined_mask
  end

  def self.next_bitkey(bitkey)
    agg = aggregate_mask
    bitkey = bitkey << 1
    return nil if (bitkey > agg) || (bitkey < 1)
    while (bitkey & agg) == 0 do
      bitkey = bitkey << 1
    end
    bitkey
  end

  def self.reveal_valid_keys(mask)
    mask = mask & self.aggregate_mask
    result = []
    (0...mask.to_s(2).size).each do |k|
      result << (mask & (1 << k))
    end
    result.reject { |x| x == 0 }
  end

  def bitkey_bits_are_unique
    if bitkey & SubSplit.aggregate_mask != 0
      errors.add(:bitkey, "one or more bits overlap with the bitkey of an existing sub_split kind")
    end
  end

  def bitkey_single_bit
    if bitkey.to_s(2).count('1') > 1
      errors.add(:bitkey, "uses more than one bit; please use the next available single-bit key (4, 8, 16, etc.)")
    end
    if bitkey < 1
      errors.add(:bitkey, "cannot be zero or negative")
    end
  end

  # Methods that return an instance of SubSplit; add a new method each time a new record is added

  def self.in
    SubSplit.find(1)
  end

  def self.out
    SubSplit.find(64)
  end

end
