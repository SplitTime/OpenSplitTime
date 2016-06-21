class EffortAnalysisRow

  delegate :name, :distance_from_start, :kind, :intermediate?, :finish?, to: :split
  delegate :segment_time, :time_in_aid, :times_from_start, to: :time_cluster

  # split_times should be an array having size == split.sub_split_bitkey_hashes.size,
  # with nil values where no corresponding split_time exists

  def initialize(split, split_times, prior_time, start_time, typical_row)
    @split = split
    @split_times = split_times
    @prior_time = prior_time
    @start_time = start_time
    @time_cluster = TimeCluster.new(split, split_times, prior_time, start_time)
    @typical_row = typical_row
  end

  def split_id
    split.id
  end

  def combined_time
    if segment_time && time_in_aid
      segment_time + time_in_aid
    elsif segment_time
      segment_time
    else
      nil
    end
  end

  def segment_time_typical
    typical_row.segment_time
  end

  def time_in_aid_typical
    typical_row.time_in_aid
  end

  def combined_time_typical
    if segment_time_typical && time_in_aid_typical
      segment_time_typical + time_in_aid_typical
    elsif segment_time_typical
      segment_time_typical
    else
      nil
    end
  end

  def segment_time_over_under
    (segment_time && typical_row.segment_time) ? segment_time - typical_row.segment_time : nil
  end

  def time_in_aid_over_under
    (time_in_aid && typical_row.time_in_aid) ? time_in_aid - typical_row.time_in_aid : nil
  end

  def combined_time_over_under
    (segment_time_over_under && time_in_aid_over_under) ? segment_time_over_under + time_in_aid_over_under : nil
  end

  private

  attr_reader :split, :split_times, :prior_time, :start_time, :time_cluster, :typical_row

end