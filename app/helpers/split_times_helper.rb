module SplitTimesHelper

  def composite_time(waypoint_group_row)
    time_array = []
    (0...waypoint_group_row.times.count).each do |i|
      time = waypoint_group_row.times[i]
      data_status = waypoint_group_row.time_data_statuses[i]
      if time
        case data_status
          when 'bad'
            element = '[*' + time_format_hhmmss(time) + '*]'
          when 'questionable'
            element = '[' + time_format_hhmmss(time) + ']'
          else
            element = time_format_hhmmss(time)
        end
      else
        element = '--:--:--'
      end
      time_array << element
    end
    time_array.join(' / ')
  end

  def waypoint_group_status(effort, waypoint_group)
    split_times = effort.split_times.where(split_id: waypoint_group)
    split_times.pluck(:data_status).compact.min
  end

end