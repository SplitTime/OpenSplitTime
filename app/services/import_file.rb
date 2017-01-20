class ImportFile
  require 'roo'
  extend ActiveModel::Naming

  attr_reader :spreadsheet, :header1, :header2

  def initialize(file_url)
    @spreadsheet = open_spreadsheet(file_url)
    return false unless spreadsheet
    @header1 = spreadsheet.row(1)
    @header2 = spreadsheet.row(2)
  end

  def split_offset
    start_column_index = header1_downcase.index("start")
    start_column_index ? start_column_index + 1 : header1.size
  end

  def effort_offset
    unit_array = %w(miles meters km kilometers)
    return 2 unless header2[0].try(:downcase)
    header2[0].downcase.include?("distance") &&
        (header2[1].blank? || unit_array.include?(header2[1])) ? 3 : 2
  end

  def valid_for_split_import?
    distance_conversion_factor &&
        (header1.size == header2.size) &&
        (effort_offset > 2)
  end

  def header1_downcase
    header1.map { |cell| cell.try(:downcase) }
  end

  def split_title_array
    header1[split_offset - 1...header1.size]
  end

  def split_distance_array
    header2[split_offset - 1...header2.size]
        .map { |distance| distance * distance_conversion_factor }
  end

  def split_header_map
    split_title_array.zip(split_distance_array).to_h
  end

  def finish_times_only?
    split_offset == header1.size
  end

  private

  VALID_EXTENSIONS = %w(csv xls xlsx)

  def open_spreadsheet(file_url)
    return nil unless file_url.present?
    spreadsheet_format = file_url.split('.').last
    filename = file_url.split('/').last
    if VALID_EXTENSIONS.include?(spreadsheet_format)
      Roo::Spreadsheet.open(file_url)
    else
      raise ArgumentError, "Unknown file type: #{filename}"
    end
  end

  def distance_conversion_factor
    @distance_conversion_factor ||= conversion_factor(header2[1])
  end

  def conversion_factor(units)
    measurement = units.to_s.downcase.first == 'k' ? 1.kilometer : 1.mile
    measurement.to.meters.value
  end
end