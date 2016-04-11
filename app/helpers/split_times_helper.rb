module SplitTimesHelper

  def composite_time(base_split_time)
    splits = base_split_time.split.waypoint_group
    time_array = []
    splits.each do |split|
      split_time = split.split_times.where(effort: base_split_time.effort).first
      element = split_time ? split_time.time_format_hhmm : '< none >'
      time_array << element
    end
    time_array.join(' / ')
  end

end