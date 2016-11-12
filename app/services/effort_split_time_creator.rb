class EffortSplitTimeCreator

  attr_reader :start_offset, :dropped_split_id

  def initialize(row_time_data, effort, current_user_id, event = nil)
    @row_time_data = row_time_data
    @effort_id = effort.id
    @current_user_id = current_user_id
    @event = event || effort.event
    initialize_return_values
    create_split_times
  end

  private

  EXCEL_BASE_DATETIME = '1899-12-30'.to_datetime

  attr_reader :row_time_data, :effort_id, :current_user_id, :event
  attr_writer :start_offset, :dropped_split_id

  def initialize_return_values
    self.start_offset = row_time_data.first || 0
    row_time_data[0] = 0 if row_time_data[0]
    self.dropped_split_id = last_bitkey_hash_with_time.try(:split_id) unless finished?
  end

  def create_split_times
    return if event_sub_split_count != row_time_data.count
    return if row_time_data.compact.empty?

    SplitTime.bulk_insert(:effort_id, :split_id, :sub_split_bitkey, :time_from_start,
                          :created_at, :updated_at, :created_by, :updated_by) do |worker|
      bitkey_hashes_with_times.each do |bitkey_hash|
        worker.add(effort_id: effort_id,
                   split_id: bitkey_hash.split_id,
                   sub_split_bitkey: bitkey_hash.bitkey,
                   time_from_start: time_to_seconds(sub_split_time_hash[bitkey_hash]),
                   created_by: current_user_id,
                   updated_by: current_user_id)
      end
    end
  end

  def sub_split_time_hash
    @sub_split_time_hash ||= sub_split_bitkey_hashes.zip(row_time_data).to_h
  end

  def event_sub_split_count
    @event_sub_split_count ||= sub_split_bitkey_hashes.count
  end

  def sub_split_bitkey_hashes
    @sub_split_bitkey_hashes ||= event.sub_split_bitkey_hashes
  end

  def bitkey_hashes_with_times
    @bitkey_hashes_with_times ||= sub_split_bitkey_hashes
                                      .select { |bitkey_hash| sub_split_time_hash[bitkey_hash].present? }
  end

  def finish_bitkey_hash
    @finish_bitkey_hash ||= sub_split_bitkey_hashes.last
  end

  def last_bitkey_hash_with_time
    bitkey_hashes_with_times.last
  end

  def finished?
    last_bitkey_hash_with_time == finish_bitkey_hash
  end

  def time_to_seconds(working_time)
    return nil if working_time.blank?
    working_time = working_time.to_datetime if working_time.is_a?(Date)
    working_time = datetime_to_seconds(working_time) if working_time.acts_like?(:time)
    if working_time.try(:to_f)
      working_time
    else
      errors.add(:effort_importer, "Invalid split time data for #{effort.last_name}. #{errors.full_messages}.")
    end
  end

  def datetime_to_seconds(value)
    start_time = value.year < 1910 ? EXCEL_BASE_DATETIME : event.start_time
    TimeDifference.between(value, start_time).in_seconds
  end
end