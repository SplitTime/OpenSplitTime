class EffortProgressRow

  delegate :bib_number, :full_name, :bio_historic, to: :effort

  def initialize(args)
    @effort = args[:effort]
    @event_framework = args[:event_framework]
    post_initialize(args)
  end

  def post_initialize(args)
    nil
  end

  def effort_id
    effort.id
  end

  def last_reported_info
    EffortSplitData.new(effort_id: effort_id,
                        lap: effort.final_lap,
                        split_name: lap_split_name(last_reported_time_point),
                        days_and_times: [effort.day_and_time(effort.final_time)])
  end

  def due_next_info
    EffortSplitData.new(effort_id: effort_id,
                        lap: due_next_time_point.lap,
                        split_name: lap_split_name(due_next_time_point),
                        days_and_times: [effort.day_and_time(time_from_start_to_next)])
  end

  def extract_attributes(*attributes)
    attributes.map { |attribute| [attribute, send(attribute)] }.to_h
  end

  private

  attr_reader :effort, :event_framework
  delegate :lap_splits, :indexed_lap_splits, :multiple_laps?, :time_points,
           :times_container, to: :event_framework

  def last_reported_split_time
    SplitTime.new(effort: effort,
                  time_point: last_reported_time_point,
                  time_from_start: effort.final_time)
  end

  def time_from_start_to_next
    predicted_upcoming_time && (predicted_upcoming_time + effort.final_time)
  end

  def predicted_upcoming_time
    @predicted_upcoming_time ||= predicted_segment_time(upcoming_segment)
  end

  def predicted_segment_time(segment)
    segment.end_point.out? ? nil : TimePredictor.segment_time(segment: segment,
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
    @due_next_time_point ||= time_points.elements_after(last_reported_time_point).first
  end

  def effort_split_data(split_times)
    split_times = Array.wrap(split_times)
    st = split_times.compact.first
    st.nil? ? {} : EffortSplitData.new(effort_id: effort_id,
                                       split_name: lap_split_name(st.time_point),
                                       lap_name: lap_name(st.lap),
                                       days_and_times: days_and_times(split_times))
  end

  def lap_split_name(time_point)
    return '' unless time_point
    lap_split = indexed_lap_splits[time_point.lap_split_key]
    bitkey = time_point.bitkey
    multiple_laps? ? lap_split.name(bitkey) : lap_split.name_without_lap(bitkey)
  end

  def lap_name(lap)
    lap ? "Lap #{lap}" : ''
  end

  def days_and_times(split_times)
    split_times.map { |split_time| split_time && effort.day_and_time(split_time.time_from_start) }
  end
end