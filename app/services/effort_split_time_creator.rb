class EffortSplitTimeCreator

  attr_reader :start_offset, :dropped_split_id

  def initialize(row_time_data, effort, current_user_id, event = nil)
    @row_time_data = row_time_data
    @effort = effort
    @current_user_id = current_user_id
    @event = event || effort.event
    initialize_return_values
    validate_row_time_data
  end

  def split_times
    @split_times ||= populated_sub_splits.map { |sub_split| split_time_build(sub_split) }
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
  attr_writer :start_offset, :dropped_split_id

  def initialize_return_values
    self.start_offset = time_to_seconds(row_time_data.first) || 0
    row_time_data[0] = 0 if row_time_data[0]
    self.dropped_split_id = populated_sub_splits.last.try(:split_id) unless finished?
  end

  def validate_row_time_data
    raise ArgumentError, "row time data contains #{row_time_data.count} elements but event requires #{event_sub_split_count} elements" if
        event_sub_split_count != row_time_data.count
  end

  def split_time_build(sub_split)
    SplitTime.new(effort_id: effort.id,
                  sub_split: sub_split,
                  time_from_start: time_to_seconds(sub_split_time_hash[sub_split]),
                  created_by: current_user_id,
                  updated_by: current_user_id)
  end

  def sub_split_time_hash
    @sub_split_time_hash ||= sub_splits.zip(row_time_data).to_h
  end

  def sub_splits
    @sub_splits ||= event.sub_splits
  end

  def populated_sub_splits
    @populated_sub_splits ||= sub_splits.select { |sub_split| sub_split_time_hash[sub_split].present? }
  end

  def event_sub_split_count
    sub_splits.count
  end
  
  def finished?
    populated_sub_splits.last == sub_splits.last
  end

  def time_to_seconds(working_time)
    return nil if working_time.blank?
    return working_time if working_time.is_a?(Numeric)
    working_time = working_time.to_datetime if working_time.is_a?(Date)
    working_time = datetime_to_seconds(working_time) if working_time.acts_like?(:time)
    if working_time.try(:to_i)
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