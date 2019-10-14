# frozen_string_literal: true

EffortAuditRow = Struct.new(:lap_split, :bitkey, :split_time, :home_time_zone, :matched_raw_times, :unmatched_raw_times,
                            keyword_init: true) do

  def name
    @name ||= lap_split.public_send(:name_without_lap, bitkey)
  end

  def parameterized_split_name
    @parameterized_split_name ||= lap_split.split.parameterized_base_name
  end

  def sub_split_kind
    SubSplit.kind(bitkey).downcase
  end

  def largest_discrepancy
    return nil unless times_in_seconds.present?

    adjusted_times = times_in_seconds.map { |seconds| (seconds - times_in_seconds.first) > 12.hours ? (seconds - 24.hours).to_i : seconds }.sort
    (adjusted_times.last - adjusted_times.first).to_i
  end

  def problem?
    return false unless joined_military_times.present?

    largest_discrepancy > EffortAuditView::DISCREPANCY_THRESHOLD
  end

  private

  def raw_times
    @raw_times ||= matched_raw_times + unmatched_raw_times
  end

  def split_times
    [split_time]
  end

  def times_in_seconds
    @times_in_seconds ||= joined_military_times.map { |military_time| TimeConversion.hms_to_seconds(military_time) }
  end

  def joined_military_times
    (split_times.map(&:military_time) | raw_times.map(&:military_time)).compact.sort
  end
end
