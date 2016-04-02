module SplitTimesHelper

  def composite_name(split_time) #TODO limit this to event_waypoint_group when that function is working
    (split_time.split.waypoint_group.order(:sub_order).map &:name).join(' / ')
  end

  def composite_time(base_split_time)
    splits = base_split_time.split.waypoint_group.order(:sub_order)
    time_array = []
    splits.each do |split|
      split_time = split.split_times.where(effort: base_split_time.effort).first
      element = split_time ? split_time.formatted_time : '< none >'
      time_array << element
    end
    time_array.join(' / ')
  end

end