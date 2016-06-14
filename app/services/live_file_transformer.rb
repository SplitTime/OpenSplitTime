class LiveFileTransformer

  require 'csv'

  def initialize(event, file = nil)
    @event = event
    @file = file || File.new("#{Rails.root}/public/packet_data_test.csv")
    @transformed_rows = []
    @file_rows = []
    create_rows_from_file
    transform_rows
  end

  def returned_rows
    transformed_rows
  end

  private

  attr_reader :event, :file
  attr_accessor :file_rows, :transformed_rows

  def create_rows_from_file
    CSV.foreach(file.path, headers: true) do |row|
      file_row = row.to_hash
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

end