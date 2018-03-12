# frozen_string_literal: true

class EffortTimesRowSerializer < BaseSerializer
  attributes *EffortTimesRow::EXPORT_ATTRIBUTES, :display_style, :stopped, :dropped, :finished
  attribute :elapsed_times, if: :show_elapsed_times
  attribute :absolute_times, if: :show_absolute_times
  attribute :segment_times, if: :show_segment_times

  def show_elapsed_times
    %w(elapsed).include?(object.display_style)
  end

  def show_absolute_times
    %w(ampm military absolute).include?(object.display_style)
  end

  def show_segment_times
    %w(segment).include?(object.display_style)
  end

  def elapsed_times
    object.time_clusters.map(&:times_from_start)
  end

  def absolute_times
    object.time_clusters.map(&:days_and_times)
  end

  def segment_times
    object.time_clusters.map { |tc| [tc.segment_time, tc.time_in_aid] }
  end

  def stopped
    object.stopped?
  end

  def dropped
    object.dropped?
  end

  def finished
    object.finished?
  end
end
