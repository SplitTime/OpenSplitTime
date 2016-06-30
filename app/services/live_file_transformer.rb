class LiveFileTransformer

  require 'csv'

  def initialize(event, file, split_id)
    @event = event
    @file = file
    @split = Split.find_by_id(split_id)
    @transformed_rows = []
    @file_rows = []
    create_rows_from_file if split
    transform_rows if split
  end

  def returned_rows
    transformed_rows
  end

  private

  attr_reader :event, :file, :split
  attr_accessor :file_rows, :transformed_rows

  def create_rows_from_file
    CSV.foreach(file.path, headers: true) do |row|
      file_row = row.to_hash
      file_row.symbolize_keys!
      zeroize_times(file_row)
      file_row[:splitId] = split_id
      file_rows << file_row
    end
  end

  def transform_rows
    calcs = EventSegmentCalcs.new(event)
    ordered_split_array = event.ordered_splits.to_a
    file_rows.each do |file_row|
      effort_data_object = LiveEffortData.new(event, file_row, calcs, ordered_split_array)
      transformed_rows << effort_data_object.response_row
    end
  end

  def split_id
    split ? split.id : nil
  end

  def zeroize_times(file_row)
    file_row[:timeIn] = zeroize(file_row[:timeIn])
    file_row[:timeOut] = zeroize(file_row[:timeOut])
  end

  def zeroize(time_string)
    time_components = time_string.split(':')
    time_components << "00" if time_components.count == 2
    time_components[0] = "0" + time_components[0] if time_components[0].length == 1
    time_components.join(":")
  end

end