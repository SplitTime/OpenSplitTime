class EffortProgressRow

  delegate :bib_number, :full_name, :bio_historic, to: :effort

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:effort, :event_framework],
                           exclusive: [:effort, :event_framework],
                           class: self.class)
    @effort = args[:effort]
    @event_data = args[:event_framework]
  end

  def effort_id
    effort.id
  end

  def last_reported_name
    lap_split_name(last_reported_time_point)
  end

  def due_next_name
    lap_split_name(due_next_time_point)
  end

  def last_reported_day_and_time
    effort.start_time + effort.final_time
  end

  def due_next_day_and_time
    due_next_time_from_start && (effort.start_time + due_next_time_from_start)
  end

  def minutes_past_due
    @minutes_past_due ||= due_next_day_and_time && ((Time.current - due_next_day_and_time) / 1.minute).round
  end

  def past_due?
    minutes_past_due && (minutes_past_due >= past_due_threshold)
  end

  private

  attr_reader :effort, :event_data
  delegate :lap_splits, :indexed_lap_splits, :multiple_laps?, :time_points,
           :times_container, :past_due_threshold, to: :event_data

  def last_reported_split_time
    SplitTime.new(effort: effort,
                  time_point: last_reported_time_point,
                  time_from_start: effort.final_time)
  end

  def due_next_time_from_start
    predicted_segment_time && (effort.final_time + predicted_segment_time)
  end

  def predicted_segment_time
    @predicted_segment_time ||= due_next_time_point.out? ? nil :
        TimePredictor.segment_time(segment: upcoming_segment,
                                   effort: effort,
                                   lap_splits: lap_splits,
                                   completed_split_time: last_reported_split_time,
                                   times_container: times_container)
  end

  def upcoming_segment
    Segment.new(begin_point: last_reported_time_point, end_point: due_next_time_point)
  end

  def last_reported_time_point
    @last_reported_time_point ||= TimePoint.new(effort.final_lap, effort.final_split_id, effort.final_bitkey)
  end

  def due_next_time_point
    @due_next_time_point ||= time_points[time_points.index(last_reported_time_point) + 1]
  end

  def lap_split_name(time_point)
    lap_split = indexed_lap_splits[time_point.lap_split_key]
    bitkey = time_point.bitkey
    multiple_laps? ? lap_split.name(bitkey) : lap_split.name_without_lap(bitkey)
  end
end