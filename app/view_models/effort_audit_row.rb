# frozen_string_literal: true

EffortAuditRow = Struct.new(:lap_split, :bitkey, :split_time, :home_time_zone, :matched_raw_times, :unmatched_raw_times,
                            keyword_init: true) do
  include Discrepancy

  def name
    @name ||= lap_split.public_send(:name_without_lap, bitkey)
  end

  def parameterized_split_name
    @parameterized_split_name ||= lap_split.split.parameterized_base_name
  end

  def sub_split_kind
    SubSplit.kind(bitkey).downcase
  end

  def problem?
    discrepancy_above_threshold?
  end

  private

  def raw_times
    @raw_times ||= matched_raw_times + unmatched_raw_times
  end

  def split_times
    [split_time]
  end
end
