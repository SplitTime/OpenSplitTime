class EffortSplitTimeCreator

  EXCEL_1900_BASE_DATETIME = '1899-12-30'.to_datetime
  EXCEL_1904_BASE_DATETIME = '1904-01-01'.to_datetime

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:row_time_data, :effort, :current_user_id],
                           exclusive: [:row_time_data, :effort, :current_user_id, :event, :time_format],
                           class: self.class)
    @row_time_data = args[:row_time_data]
    @effort = args[:effort]
    @current_user_id = args[:current_user_id]
    @event = args[:event] || effort.event
    @time_format = args[:time_format]
    set_start_offset
    validate_row_time_data
  end

  def split_times
    @split_times ||= populated_time_points.map { |time_point| split_time_build(time_point) }
  end

  def create_split_times
    split_times.each do |split_time|
      split_time.save if split_time.changed?
    end
  end

  private

  attr_reader :row_time_data, :effort, :current_user_id, :event, :time_format

  def set_start_offset
    if military_times?
      effort.event_start_time = event.start_time # Avoids a database query to determine event_start_time
      effort.start_time = military_time_to_day_and_time(row_time_data.first, time_points.first)
    else
      proposed_offset = time_to_seconds(row_time_data.first) || 0
      effort.start_offset = proposed_offset unless proposed_offset == 0 # Avoid inadvertently destroying existing offsets
      row_time_data[0] = 0 unless start_time_only?
    end
    effort.save if effort.changed?
  end

  def split_time_build(time_point)
    split_time = SplitTime.find_or_initialize_by(effort_id: effort.id,
                                                 lap: time_point.lap,
                                                 split_id: time_point.split_id,
                                                 sub_split_bitkey: time_point.bitkey,
                                                 created_by: current_user_id)
    split_time.time_from_start = convert_to_seconds(time_point)
    split_time
  end

  def convert_to_seconds(time_point)
    working_time = time_points_time_hash[time_point]
    military_times? ? military_time_to_seconds(working_time, time_point) : time_to_seconds(working_time)
  end

  def populated_time_points
    @populated_time_points ||= time_points.select { |time_point| time_points_time_hash[time_point].present? }
  end

  def time_points_time_hash
    @time_points_time_hash ||= time_points.zip(row_time_data).to_h
  end

  def time_points
    @time_points ||= event.laps_unlimited? ?
        event.cycled_time_points.first(row_time_data.size) :
        event.required_time_points
  end

  def time_points_count
    time_points.size
  end

  def time_to_seconds(working_time)
    case
    when working_time.blank?
      nil
    when working_time.is_a?(Numeric)
      working_time
    when working_time.is_a?(Date)
      datetime_to_seconds(working_time.to_datetime)
    when working_time.acts_like?(:time)
      datetime_to_seconds(working_time)
    when working_time.is_a?(String)
      TimeConversion.hms_to_seconds(working_time)
    when working_time.try(:to_i)
      working_time
    else
      errors.add(:effort_split_time_creator, "Invalid time data for #{effort.full_name}. #{errors.full_messages}.")
    end
  end

  def datetime_to_seconds(datetime)
    start_time = case
                 when datetime.year < 1903
                   EXCEL_1900_BASE_DATETIME
                 when datetime.year < 1907
                   EXCEL_1904_BASE_DATETIME
                 else
                   event.start_time
                 end
    TimeDifference.between(datetime, start_time).in_seconds
  end

  def military_time_to_day_and_time(military_time, time_point)
    IntendedTimeCalculator.day_and_time(military_time: military_time, effort: effort, time_point: time_point)
  end

  def military_time_to_seconds(military_time, time_point)
    military_time_to_day_and_time(military_time, time_point) - effort.start_time
  end

  def military_times?
    time_format == 'military'
  end

  def start_time_only?
    row_time_data[1..-1].compact.empty?
  end

  def validate_row_time_data
    raise ArgumentError, "row time data contains #{row_time_data.size} elements " +
        "but event requires #{time_points_count} elements" if time_points_count != row_time_data.size
  end
end