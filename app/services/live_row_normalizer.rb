# frozen_string_literal: true

class LiveRowNormalizer
  KEY_MAP = {'bib' => 'bib_number', 'bib_#' => 'bib_number', 'drop' => 'dropped_here', 'dropped' => 'dropped_here',
             'stopped_here' => 'dropped_here', 'stopped' => 'dropped_here', 'comments' => 'remarks', 'time' => 'time_in'}
  PERMITTED_PARAMETERS = [:bib_number, :time_in, :time_out, :pacer_in, :pacer_out, :dropped_here, :remarks]

  def self.normalize(csv_row)
    new(csv_row).normalize
  end

  def initialize(csv_row)
    @proto_record = ProtoRecord.new(csv_row.to_hash)
  end

  def normalize
    normalize_headers
    strip_white_space
    normalize_times
    normalize_booleans
    proto_record.to_h
  end

  private

  attr_reader :proto_record

  TIME_PARAMS = [:time_in, :time_out]
  BOOLEAN_PARAMS = [:pacer_in, :pacer_out, :dropped_here]
  AFFIRMATIVE_LETTERS = %w(t y)

  def normalize_headers
    proto_record.to_h.keys.each { |key| proto_record[key.to_s.underscore.tr(' ', '_')] = proto_record.delete_field(key) }
    proto_record.map_keys!(KEY_MAP)
    proto_record.slice_permitted!(PERMITTED_PARAMETERS)
  end

  def strip_white_space
    proto_record.strip_white_space!
  end

  def normalize_times
    TIME_PARAMS.each { |time_param| proto_record[time_param] = TimeConversion.file_to_military(proto_record[time_param]) }
  end

  def normalize_booleans
    BOOLEAN_PARAMS.each { |boolean_param| proto_record[boolean_param] = boolean_string(proto_record[boolean_param]) }
  end

  def boolean_string(string)
    return nil unless string.present?
    AFFIRMATIVE_LETTERS.include?(string[0].downcase) ? 'true' : 'false'
  end
end
