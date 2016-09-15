class EffortTimesRow

  include PersonalInfo

  attr_reader :effort, :time_clusters
  delegate :id, :first_name, :last_name, :gender, :bib_number, :age, :state_code, :country_code, :data_status,
           :bad?, :questionable?, :good?, :confirmed?, :segment_time, :place, :start_offset, to: :effort

  def initialize(effort, splits, split_times, event_start_time)
    @effort = effort
    @splits = splits
    @split_times = split_times.index_by(&:bitkey_hash)
    @event_start_time = event_start_time
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

  attr_reader :splits, :split_times, :event_start_time

  def effective_start_time
    event_start_time + start_offset
  end

  def create_time_clusters
    prior_time = 0
    drop_display_split_id = nil
    if effort.dropped_split_id
      ordered_split_ids = splits.map(&:id)
      drop_split_index = ordered_split_ids.index(effort.dropped_split_id)
      drop_display_split_id = ordered_split_ids[drop_split_index + 1] if drop_split_index
    end
    splits.each do |split|
      time_cluster = TimeCluster.new(split,
                                     related_split_times(split),
                                     prior_time,
                                     effective_start_time,
                                     drop_display_split_id == split.id)
      time_clusters << time_cluster
      prior_time = time_cluster.times_from_start.compact.last if time_cluster.times_from_start.compact.present?
    end
  end

  def related_split_times(split)
    split.sub_split_bitkey_hashes.collect { |bitkey_hash| split_times[bitkey_hash] }
  end

end