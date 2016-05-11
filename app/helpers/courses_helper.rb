module CoursesHelper

  def plan_combined_times(split, time_data)
    waypoint_group = @event.waypoint_groups.detect { |x,y| (x == split.id) | (y == split.id) } # TODO modify to work with waypoint groups larger than two elements
    time_array = []
    waypoint_group.each do |split_id|
      time = time_data[split_id]
      element = time ? time_format_hhmm(time) : '< no data >'
      time_array << element
    end
    time_array.join(' / ')
  end

  def plan_combined_time_of_day(split, time_data)
    waypoint_group = @event.waypoint_groups.detect { |x,y| (x == split.id) | (y == split.id) } # TODO modify to work with waypoint groups larger than two elements
    time_array = []
    waypoint_group.each do |split_id|
      time = time_data[split_id]
      element = time ? day_time_format(@event.first_start_time + time.seconds) : '< no data >'
      time_array << element
    end
    time_array.join(' / ')
  end

  def plan_segment_time(split, time_data)
    split_ids = @event.ordered_split_ids
    position = split_ids.index(split.id)
    return 0 if position == 0
    time_data[split.id] - time_data[split_ids[position - 1]]
  end

  def percent_of_total_time(split, time_data)
    plan_segment_time(split, time_data) / expected_time
  end

  def plan_time_in_aid(split, time_data)
    waypoint_group = @event.waypoint_groups.detect { |x,y| (x == split.id) | (y == split.id) } # TODO modify to work with waypoint groups larger than two elements
    time_data[waypoint_group.last] - time_data[waypoint_group.first]
  end

  def expected_time
    return nil if params[:expected_time].blank?
    # TODO: do regex test here
    h = params[:expected_time].split(":")[0].to_i
    m = params[:expected_time].split(":")[1].to_i
    ((h * 60 * 60) + (m * 60))
  end

  def normalize_time_data(time_data, expected_time)
    average_finish_time = time_data[@event.ordered_split_ids.last]
    return time_data if average_finish_time.nil?
    factor = expected_time / average_finish_time
    time_data.each { |k,v| time_data[k] = v * factor }
  end

  def efforts_analyzed
    @event.course.relevant_efforts(expected_time).count
  end

  def event_years_analyzed
    event_dates = @event.course.most_recent_events(5).pluck(:first_start_time)
    result = []
    event_dates.sort.each { |date| result << date.year }
    result
  end

  def segment_is_full_course?
    (@segment.begin_split == @course.start_split) && (@segment.end_split == @course.finish_split)
  end

end