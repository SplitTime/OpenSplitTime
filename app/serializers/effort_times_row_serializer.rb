# frozen_string_literal: true

class EffortTimesRowSerializer < BaseSerializer
  attributes *EffortTimesRow::EXPORT_ATTRIBUTES, :display_style, :stopped, :dropped, :finished
  attribute :elapsed_times, if: :show_elapsed_times
  attribute :absolute_times, if: :show_absolute_times
  attribute :segment_times, if: :show_segment_times
  attribute :pacer_flags, if: :show_pacer_flags
  attribute :stopped_here_flags, if: :show_stopped_here_flags
  attribute :time_data_statuses, if: :show_time_data_statuses

  def show_elapsed_times
    %w(elapsed all).include?(object.display_style)
  end

  def show_absolute_times
    %w(ampm military absolute all).include?(object.display_style)
  end

  def show_segment_times
    %w(segment all).include?(object.display_style)
  end

  def show_pacer_flags
    object.display_style == 'all'
  end

  def show_stopped_here_flags
    object.display_style == 'all'
  end

  def show_time_data_statuses
    object.display_style == 'all'
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

  def time_data_statuses
    object.time_clusters.map(&:time_data_statuses)
  end

  def pacer_flags
    object.time_clusters.map(&:pacer_flags)
  end

  def stopped_here_flags
    object.time_clusters.map(&:stopped_here_flags)
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
