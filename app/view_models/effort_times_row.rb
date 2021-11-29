# frozen_string_literal: true

class EffortTimesRow
  include PersonalInfo, Rankable, TimeFormats

  EXPORT_ATTRIBUTES = [:overall_rank, :gender_rank, :bib_number, :first_name, :last_name, :gender, :age, :state_code, :country_code, :flexible_geolocation]

  attr_reader :effort, :display_style
  delegate :id, :first_name, :last_name, :full_name, :gender, :bib_number, :age, :city, :state_code, :country_code, :data_status,
           :bad?, :questionable?, :good?, :confirmed?, :segment_time, :overall_rank, :gender_rank, :scheduled_start_offset,
           :started?, :in_progress?, :stopped?, :dropped?, :finished?, to: :effort

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:effort, :lap_splits, :split_times],
                           exclusive: [:effort, :lap_splits, :split_times, :display_style],
                           class: self.class)
    @effort = args[:effort] # Use an enriched effort for optimal performance
    @lap_splits = args[:lap_splits]
    @split_times = args[:split_times]
    @display_style = args[:display_style]
  end

  def total_time_in_aid
    time_clusters.map(&:time_in_aid).compact.sum
  end

  def total_segment_time
    time_clusters.map(&:segment_time).compact.sum
  end

  def time_clusters
    @time_clusters ||= lap_splits.map do |lap_split|
      TimeCluster.new(split_times_data: related_split_times(lap_split),
                      finish: finish_cluster?(lap_split),
                      show_indicator_for_stop: show_indicator_for_stop?(lap_split))
    end
  end
  
  def show_elapsed_times?
    display_style.in? %w(elapsed all)
  end

  def show_absolute_times?
    display_style.in? %w(ampm military absolute all)
  end

  def show_segment_times?
    display_style.in? %w(segment all)
  end

  def show_pacer_flags?
    display_style == 'all'
  end

  def show_stopped_here_flags?
    display_style == 'all'
  end

  def show_time_data_statuses?
    display_style == 'all'
  end

  def elapsed_times
    time_clusters.map(&:times_from_start)
  end

  def absolute_times
    time_clusters.map(&:absolute_times_local)
  end

  def segment_times
    time_clusters.map { |tc| [tc.segment_time, tc.time_in_aid] }
  end

  def time_data_statuses
    time_clusters.map(&:time_data_statuses)
  end

  def pacer_flags
    time_clusters.map(&:pacer_flags)
  end

  def stopped_here_flags
    time_clusters.map(&:stopped_here_flags)
  end

  alias_method :stopped, :stopped?
  alias_method :dropped, :dropped?
  alias_method :finished, :finished?

  private

  attr_reader :lap_splits, :split_times

  def indexed_split_times
    @indexed_split_times ||= split_times.index_by(&:time_point)
  end

  def finish_cluster?(lap_split)
    if multiple_laps?
      cluster_includes_last_data?(lap_split)
    else
      lap_split.split.finish?
    end
  end

  def show_indicator_for_stop?(lap_split)
    multiple_laps? || !finish_cluster?(lap_split)
  end

  def cluster_includes_last_data?(lap_split)
    related_split_times(lap_split).compact.include?(last_split_time)
  end

  def related_split_times(lap_split)
    lap_split.time_points.map { |time_point| indexed_split_times.fetch(time_point, SplitTimeData.new) }
  end

  def last_split_time
    @last_split_time ||=
        lap_splits.flat_map(&:time_points).map { |time_point| indexed_split_times[time_point] }.compact.last
  end

  def lap_split_keys
    @lap_split_keys ||= lap_splits.map(&:key)
  end

  def multiple_laps?
    effort.laps_required != 1
  end
end
