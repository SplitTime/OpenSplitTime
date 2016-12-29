class LiveFileTransformer
  require 'csv'

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
    @aid_station = args[:aid_station] || AidStation.find_by(event: event, split: split)
    @file_rows = []
    create_rows_from_file if split
    set_import_sequence if aid_station && last_row_sequence_id
  end

  def returned_rows
    @returned_rows ||=
        file_rows.map { |file_row| NewLiveEffortData.new(event: event,
                                                         params: file_row,
                                                         times_container: times_container,
                                                         ordered_splits: ordered_splits).response_row }
  end

  def prior_sequence_id
    @prior_sequence_id ||= aid_station && aid_station.import_sequence_id
  end

  def last_row_sequence_id
    @last_row_sequence_id ||= file_rows.present? && file_rows.last[:sequenceId]
  end

  private

  attr_reader :event, :file, :split, :aid_station, :times_container
  attr_accessor :file_rows

  def create_rows_from_file
    CSV.foreach(file.path, headers: true) do |row|
      next if row.empty? || row_already_recorded?(row)
      file_row = LiveRowNormalizer.normalize(row)
      file_row[:splitId] = split_id
      file_rows << file_row
    end
  end

  def set_import_sequence
    aid_station.update(import_sequence_id: last_row_sequence_id) if last_row_sequence_id > aid_station.import_sequence_id
  end

  def row_already_recorded?(row)
    sequence_id(row) && prior_sequence_id && (sequence_id(row) <= prior_sequence_id)
  end

  def sequence_id(row)
    row[:sequenceId].to_i if (row[:sequenceId] && row[:sequenceId].numeric?)
  end

  def split_id
    @split_id ||= split && split.id
  end

  def ordered_splits
    @ordered_splits ||= event.ordered_splits.to_a
  end
end