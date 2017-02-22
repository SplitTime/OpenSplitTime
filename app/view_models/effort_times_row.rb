class EffortTimesRow
  include TimeFormats
  EXPORT_ATTRIBUTES = [:overall_rank, :gender_rank, :bib_number, :full_name, :gender, :age, :state_code, :country_code]

  include PersonalInfo

  attr_reader :effort, :time_clusters
  delegate :id, :first_name, :last_name, :gender, :bib_number, :age, :state_code, :country_code, :data_status,
           :bad?, :questionable?, :good?, :confirmed?, :segment_time, :overall_rank, :gender_rank, :start_offset, to: :effort

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:effort, :lap_splits, :split_times],
                           exclusive: [:effort, :lap_splits, :split_times],
                           class: self.class)
    @effort = args[:effort] # Use an enriched effort for optimal performance
    @lap_splits = args[:lap_splits]
    @split_times = args[:split_times]
    @time_clusters = []
    create_time_clusters
  end

  def total_time_in_aid
    time_clusters.map(&:time_in_aid).compact.sum
  end

  def total_segment_time
    time_clusters.map(&:segment_time).sum
  end

  def export_row
    EXPORT_ATTRIBUTES.map { |attr| effort.send(attr) } + time_clusters.map { |tc| tc.times_from_start.map { |tfs| time_format_hhmmss(tfs) } }.flatten
  end

  private

  attr_reader :lap_splits, :split_times

  def indexed_split_times
    @indexed_split_times ||=
        split_times.index_by { |row| TimePoint.new(row.lap, row.split_id, row.sub_split_bitkey) }
  end

  def create_time_clusters
    prior_time = 0
    lap_splits.each do |lap_split|
      time_cluster = TimeCluster.new(finish: finish_cluster?(lap_split),
                                     split_times_data: related_split_times(lap_split),
                                     prior_time: prior_time,
                                     start_time: effort.start_time,
                                     drop_display: display_stopped?(lap_split))
      time_clusters << time_cluster
      prior_time = time_cluster.times_from_start.compact.last if time_cluster.times_from_start.compact.present?
    end
  end

  def finish_cluster?(lap_split)
    if multiple_laps?
      cluster_includes_last_data?(lap_split)
    else
      lap_split.split.finish?
    end
  end

  def cluster_includes_last_data?(lap_split)
    related_split_times(lap_split).compact.include?(last_split_time)
  end

  def related_split_times(lap_split)
    lap_split.time_points.map { |time_point| indexed_split_times[time_point] }
  end

  def last_split_time
    @last_split_time ||=
        lap_splits.map(&:time_points).flatten.map { |time_point| indexed_split_times[time_point] }.compact.last
  end

  def display_stopped?(lap_split)
    stopped_display_key && (lap_split.key == stopped_display_key)
  end

  def stopped_display_key
    @stopped_display_key ||= lap_split_keys[stopped_key_index + 1] if stopped_key_index
  end

  def stopped_key_index
    @stopped_key_index ||= lap_split_keys.index(stopped_split_time_key)
  end

  def stopped_split_time_key
    LapSplitKey.new(stopped_split_time.lap, stopped_split_time.split_id) if stopped_split_time
  end

  def stopped_split_time
    @stopped_split_time ||= split_times.sort_by(&:time_from_start).reverse.find(&:stopped_here)
  end

  def lap_split_keys
    @lap_split_keys ||= lap_splits.map(&:key)
  end

  def multiple_laps?
    effort.laps_required != 1
  end
end