class ImportFile
  require 'roo'
  extend ActiveModel::Naming

  attr_reader :spreadsheet, :header1, :header2

  def initialize(file)
    @spreadsheet = open_spreadsheet(file)
    return false unless spreadsheet
    @header1 = spreadsheet.row(1)
    @header2 = spreadsheet.row(2)
  end

  def split_offset
    start_column_index = header1_downcase.index("start")
    start_column_index ? start_column_index + 1 : header1.size
  end

  def effort_offset
    unit_array = %w[miles meters km kilometers]
    return 2 unless header2[0].try(:downcase)
    header2[0].downcase.include?("distance") &&
        (header2[1].blank? || unit_array.include?(header2[1])) ? 3 : 2
  end

  def header1_downcase
    header1.map { |cell| cell ? cell.downcase : nil }
  end

  def split_title_array
    header1[split_offset - 1..header1.size - 1]
  end

  def split_distance_array
    header2[split_offset - 1..header2.size - 1]
  end

  def finish_times_only?
    split_offset == header1.size
  end

  private

  def open_spreadsheet(file)
    return nil unless file
    spreadsheet_format = File.extname(file.original_filename)
    case spreadsheet_format
      # when '.csv' then
      #   Roo::Spreadsheet.open(file.path, :csv)
      when '.xls' then
        Roo::Spreadsheet.open(file.path)
      when '.xlsx' then
        Roo::Spreadsheet.open(file.path)
      else
        raise "Unknown file type: #{file.original_filename}"
    end
  end

end