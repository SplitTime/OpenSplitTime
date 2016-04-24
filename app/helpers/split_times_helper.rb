module SplitTimesHelper

  def composite_time(effort, base_split)
    splits = base_split.waypoint_group
    time_array = []
    splits.each do |split|
      split_time = effort.split_times.where(split_id: split.id).first
      if split_time
        case split_time.data_status
          when 'bad'
            element = '[*' + split_time.formatted_time_hhmmss + '*]'
          when 'questionable'
            element = '[' + split_time.formatted_time_hhmmss + ']'
          else
            element = split_time.formatted_time_hhmmss
        end
      else
        element = '--:--:--'
      end
      time_array << element
    end
    time_array.join(' / ')
  end

  def status(effort, split)
    split_times = effort.split_times.where(split_id: split.waypoint_group.pluck(:id))
    split_times.pluck(:data_status).compact.min
  end

end