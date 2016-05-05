class EffortShowView
  attr_accessor :effort, :waypoint_group_table, :split_data
  attr_reader :split_rows, :waypoint_group_rows

  def initialize(effort)
    @effort = effort
    @split_data = effort.event.ordered_splits.pluck_to_hash(:id, :name, :distance_from_start, :sub_order, :kind)
    @waypoint_group_table = create_waypoint_group_table
    @split_rows = {}
    @waypoint_group_rows = {}
    append_split_time_data
    create_split_rows
    create_waypoint_group_rows
  end

  def total_time_in_aid
    waypoint_group_rows.sum { |unicorn| unicorn.time_in_aid }
  end

  private

  def append_split_time_data
    split_time_data_table = effort.split_times.index_by(&:split_id)
    split_data.each do |split_data_set|
      match = split_time_data_table[split_data_set[:id]]
      if match
        split_data_set[:time_from_start] = match.time_from_start
        split_data_set[:data_status] = match.data_status
      end
    end
  end

  def create_split_rows
    prior_time = 0
    split_data.each do |split_data_set|
      split_row = SplitRow.new(split_data_set, prior_time)
      split_rows[split_row.split_id] = split_row
      prior_time = split_data_set[:time_from_start] if split_data_set[:time_from_start]
    end
  end

  def create_waypoint_group_rows
    waypoint_group_table.each do |group|
      group_of_rows = []
      group.each { |split_id| group_of_rows << split_rows[split_id] }
      waypoint_group_row = WaypointGroupRow.new(group, group_of_rows)
      @waypoint_group_rows[group.first] = waypoint_group_row
    end
  end

  def create_waypoint_group_table
    result = []
    @split_data.group_by { |e| e[:distance_from_start] }.each do |_,v|
      result << v.map { |x| x[:id] }
    end
    result
  end

end