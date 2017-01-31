class EffortTimesRow

  include PersonalInfo

  attr_reader :effort, :time_clusters
  delegate :id, :first_name, :last_name, :gender, :bib_number, :age, :state_code, :country_code, :data_status,
           :bad?, :questionable?, :good?, :confirmed?, :segment_time, :overall_rank, :gender_rank, :start_offset, to: :effort

  def initialize(effort, lap_splits, split_times_data)
    @effort = effort # Use an enriched effort for optimal performance
    @lap_splits = lap_splits
    @split_times_data = split_times_data
    @time_clusters = []
    create_time_clusters
  end

  def total_time_in_aid
    time_clusters.map(&:time_in_aid).sum
  end

  def total_segment_time
    time_clusters.map(&:segment_time).sum
  end

  private

  attr_reader :lap_splits, :split_times_data

  def indexed_split_times_data
    @indexed_split_times_data ||=
        split_times_data.index_by { |row| TimePoint.new(row[:lap], row[:split_id], row[:sub_split_bitkey]) }
  end

  def create_time_clusters
    prior_time = 0
    lap_splits.each do |lap_split|
      time_cluster = TimeCluster.new(finish_cluster?(lap_split),
                                     related_split_times_data(lap_split),
                                     prior_time,
                                     effort.start_time,
                                     display_dropped?(lap_split))
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
    related_split_times_data(lap_split).compact.include?(last_split_time_data)
  end

  def related_split_times_data(lap_split)
    lap_split.time_points.map { |time_point| indexed_split_times_data[time_point] }
  end

  def last_split_time_data
    @last_split_time_data ||=
        lap_splits.map(&:time_points).flatten.map { |time_point| indexed_split_times_data[time_point] }.compact.last
  end

  def display_dropped?(lap_split)
    dropped_display_key && (lap_split.key == dropped_display_key)
  end

  def dropped_display_key
    @dropped_display_key ||= lap_split_keys[dropped_key_index + 1] if dropped_key_index
  end

  def dropped_key_index
    @dropped_key_index ||= lap_split_keys.index(effort.dropped_key)
  end

  def lap_split_keys
    @lap_split_keys ||= lap_splits.map(&:key)
  end

  def multiple_laps?
    effort.laps_required != 1
  end
end