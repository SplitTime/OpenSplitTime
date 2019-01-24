# frozen_string_literal: true

module TimePointMethods
  extend ActiveSupport::Concern

  def in_sub_split?
    kind == 'In'
  end

  def out_sub_split?
    kind == 'Out'
  end

  def sub_split
    SubSplit.new(split_id, bitkey)
  end

  def sub_split=(sub_split)
    self.split_id = sub_split.split_id
    self.bitkey = sub_split.bitkey
  end

  def sub_split_kind
    SubSplit.kind(bitkey)
  end

  def sub_split_kind=(sub_split_kind)
    self.bitkey = SubSplit.bitkey(sub_split_kind)
  end

  alias_method :kind, :sub_split_kind
  alias_method :kind=, :sub_split_kind=

  def time_point
    TimePoint.new(lap, split_id, bitkey)
  end

  def time_point=(time_point)
    self.lap = time_point.lap
    self.split_id = time_point.split_id
    self.bitkey = time_point.bitkey
  end
end
