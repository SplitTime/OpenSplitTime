class WaypointGroupRow
  attr_accessor :waypoint_group, :name, :distance_from_start, :begin_time, :end_time, :times, :time_data_statuses, :segment_time, :time_in_aid, :data_status, :kind

  def initialize(waypoint_group, split_rows)
    @waypoint_group = waypoint_group
    begin_split_row = split_rows.first
    end_split_row = split_rows.count > 1 ? split_rows.last : SplitRow.new({})
    @name = (split_rows.map(&:name)).join(' / ')
    @distance_from_start = begin_split_row.distance_from_start
    @begin_time = begin_split_row.time_from_start
    @end_time = end_split_row.time_from_start
    @times = split_rows.map { |split_row| split_row.time_from_start }
    @time_data_statuses = split_rows.map { |split_row| split_row.data_status }
    @segment_time = begin_split_row.segment_time
    @time_in_aid = (end_split_row.time_from_start && begin_split_row.time_from_start) ?
        end_split_row.segment_time :
        nil
    @data_status = DataStatus.get_lowest_data_status(split_rows.map(&:data_status))
    @kind = begin_split_row.kind
  end

  def start?
    kind == 0
  end

  def finish?
    kind == 1
  end

  def waypoint?
    kind == 2
  end

end