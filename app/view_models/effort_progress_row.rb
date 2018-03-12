# frozen_string_literal: true

class EffortProgressRow

  attr_reader :effort
  delegate :bib_number, :full_name, :bio_historic, to: :effort

  def initialize(args)
    @effort = args[:effort]
    @event_framework = args[:event_framework]
    post_initialize(args)
  end

  def post_initialize(args)
    nil
  end

  def effort_slug
    effort.slug
  end

  def last_reported_info
    effort_split_data(last_reported_split_time.lap, last_reported_split_time)
  end

  def due_next_info
    effort_split_data(due_next_split_time.lap, due_next_split_time)
  end

  def extract_attributes(*attributes)
    attributes.map { |attribute| [attribute, send(attribute)] }.to_h
  end

  private

  attr_reader :event_framework
  delegate :lap_splits, :indexed_lap_splits, :multiple_laps?, :time_points,
           :times_container, to: :event_framework

  def last_reported_split_time
    SplitTime.new(effort: effort, time_point: last_reported_time_point, time_from_start: effort.final_time)
  end

  def due_next_split_time
    SplitTime.new(effort: effort, time_point: due_next_time_point, time_from_start: time_from_start_to_next)
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
    TimePoint.new(effort.final_lap, effort.final_split_id, effort.final_bitkey)
  end

  def due_next_time_point
    time_points.elements_after(last_reported_time_point).first
  end

  def effort_split_data(lap, split_times)
    split_times = Array.wrap(split_times)
    st = split_times.compact.first
    EffortSplitData.new(effort_slug: effort_slug,
                        lap_name: lap_name(lap),
                        split_name: st && lap_split_name(st.time_point),
                        days_and_times: days_and_times(split_times))
  end

  def lap_name(lap)
    (lap && multiple_laps?) ? "Lap #{lap}" : ''
  end

  def lap_split_name(time_point)
    return '' unless time_point
    lap_split = indexed_lap_splits[time_point.lap_split_key]
    bitkey = time_point.bitkey
    multiple_laps? ? lap_split.name(bitkey) : lap_split.name_without_lap(bitkey)
  end

  def days_and_times(split_times)
    split_times.map { |split_time| split_time && effort.day_and_time(split_time.time_from_start) }
  end
end
