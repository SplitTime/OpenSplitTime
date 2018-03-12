# frozen_string_literal: true

class LiveFileTransformer
  require 'csv'

  def self.returned_rows(args)
    new(args).returned_rows
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:event, :file],
                           required_alternatives: [:split, :split_id],
                           exclusive: [:event, :file, :split_id, :times_container],
                           class: self.class)
    @event = args[:event]
    @file = args[:file]
    @split = args[:split] || Split.find_by(id: args[:split_id])
    @times_container = args[:times_container] || SegmentTimesContainer.new(calc_model: :stats)
    @file_rows = []
    create_rows_from_file if split
  end

  def returned_rows
    transformed_rows.reject { |row| row[:identical] }
  end

  def transformed_rows
    @transformed_rows ||= file_rows.map do |file_row|
      LiveEffortData.response_row(event: event,
                                  params: file_row,
                                  times_container: times_container,
                                  ordered_splits: ordered_splits)
    end
  end

  private

  attr_reader :event, :file, :split, :times_container
  attr_accessor :file_rows

  def create_rows_from_file
    CSV.foreach(file.path, headers: true) do |row|
      next if row.empty?
      file_row = LiveRowNormalizer.normalize(row)
      file_row[:split_id] = split_id
      file_row[:lap] ||= 1
      file_rows << file_row
    end
  end

  def split_id
    @split_id ||= split.id
  end

  def ordered_splits
    @ordered_splits ||= event.ordered_splits
  end
end
