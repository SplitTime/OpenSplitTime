# frozen_string_literal: true

module Discrepancy
  extend ActiveSupport::Concern

  DISCREPANCY_THRESHOLD = 1.minute

  def largest_discrepancy
    return nil unless times_in_seconds.present?

    adjusted_times = times_in_seconds.map { |seconds| (seconds - times_in_seconds.first) > 12.hours ? (seconds - 24.hours).to_i : seconds }.sort
    (adjusted_times.last - adjusted_times.first).to_i
  end

  private

  def times_in_seconds
    @times_in_seconds ||= joined_military_times.map { |military_time| TimeConversion.hms_to_seconds(military_time) }
  end

  def joined_military_times
    (split_times.map(&:military_time) | raw_times.map(&:military_time)).compact.sort
  end

  def discrepancy_above_threshold?
    largest_discrepancy.present? && largest_discrepancy > self.class::DISCREPANCY_THRESHOLD
  end
end
