class EffortSplitTimeCreator

  attr_reader :start_offset

  def initialize(row_time_data, effort, current_user_id, event = nil)
    @row_time_data = row_time_data
    @effort = effort
    @current_user_id = current_user_id
    @event = event || effort.event
    initialize_return_values
    validate_row_time_data
  end

  def split_times
    @split_times ||= populated_time_points.map { |time_point| split_time_build(time_point) }
  end

  def create_split_times
    SplitTime.bulk_insert do |worker|
      split_times.each do |split_time|
        worker.add(bulk_insert_attributes(split_time))
      end
    end
  end

  def bulk_insert_attributes(split_time)
    split_time.attributes.symbolize_keys.reject { |attr, _| [:id, :created_at, :updated_at].include?(attr) }
  end

  private

  EXCEL_BASE_DATETIME = '1899-12-30'.to_datetime
  CUTOVER_YEAR = 1910

  attr_reader :row_time_data, :effort, :current_user_id, :event
  attr_writer :start_offset

  def initialize_return_values
    self.start_offset = time_to_seconds(row_time_data.first) || 0
    row_time_data[0] = 0 if row_time_data[0]
  end

  def validate_row_time_data
    raise ArgumentError, "row time data contains #{row_time_data.size} elements but event requires #{time_points_count} elements" if
        time_points_count != row_time_data.size
  end

  def split_time_build(time_point)
    SplitTime.new(effort_id: effort.id,
                  time_point: time_point,
                  time_from_start: time_to_seconds(time_points_time_hash[time_point]),
                  created_by: current_user_id,
                  updated_by: current_user_id)
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

  def datetime_to_seconds(value)
    start_time = value.year < CUTOVER_YEAR ? EXCEL_BASE_DATETIME : event.start_time
    TimeDifference.between(value, start_time).in_seconds
  end
end