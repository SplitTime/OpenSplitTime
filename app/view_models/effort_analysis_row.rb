class EffortAnalysisRow

  attr_reader :split_times
  delegate :base_name, :distance_from_start, :kind, :intermediate?, :finish?, to: :split
  delegate :segment_time, :time_in_aid, :times_from_start, to: :time_cluster

  # split_times should be an array having size == split.sub_splits.size,
  # with nil values where no corresponding split_time exists

  def initialize(split, split_times, prior_split, prior_split_time, start_time, typical_row = nil)
    @split = split
    @split_times = split_times
    @prior_split = prior_split
    @prior_split_time = prior_split_time
    @start_time = start_time
    @time_cluster = TimeCluster.new(split, split_times, prior_time, start_time)
    @typical_row = typical_row
  end

  def split_id
    split.id
  end

  def segment_name
    segment.name
  end

  def combined_time
    return nil unless segment_time
    time_in_aid ? segment_time + time_in_aid : segment_time
  end

  def segment_time_typical
    typical_row ? typical_row.segment_time : nil
  end

  def time_in_aid_typical
    typical_row ? typical_row.time_in_aid : nil
  end

  def combined_time_typical
    return nil unless segment_time_typical
    time_in_aid_typical ? segment_time_typical + time_in_aid_typical : segment_time_typical
  end

  def segment_time_over_under
    (segment_time && typical_row && typical_row.segment_time) ? segment_time - typical_row.segment_time : nil
  end

  def time_in_aid_over_under
    (time_in_aid && typical_row && typical_row.time_in_aid) ? time_in_aid - typical_row.time_in_aid : nil
  end

  def combined_time_over_under
    (segment_time_over_under && time_in_aid_over_under) ? segment_time_over_under + time_in_aid_over_under : nil
  end

  def segment_over_under_percent
    (segment_time_over_under && segment_time_typical) ? segment_time_over_under / segment_time_typical : nil
  end

  private

  attr_reader :split, :prior_split, :prior_split_time, :start_time, :time_cluster, :typical_row

  def prior_time
    @prior_time ||= prior_split_time.time_from_start
  end

  def segment
    @segment ||= end_sub_split && Segment.new(begin_sub_split: prior_split_time.sub_split,
                                              end_sub_split: end_sub_split,
                                              begin_split: prior_split,
                                              end_split: split)
  end

  def end_sub_split
    split_times.compact.first.try(:sub_split)
  end
end