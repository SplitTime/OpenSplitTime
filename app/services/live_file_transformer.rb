# frozen_string_literal: true

class LiveFileTransformer
  BYTE_ORDER_MARK = String.new("\xEF\xBB\xBF").force_encoding('UTF-8').freeze


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
    pp "File rows are: \n#{file_rows}"
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
    rows = SmarterCSV.process(file.path, remove_empty_values: false, row_sep: :auto, force_utf8: true,
                              strip_chars_from_headers: BYTE_ORDER_MARK, downcase_header: false, strings_as_keys: true)
    rows.each do |row|
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
