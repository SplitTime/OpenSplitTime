class Importer
  require 'roo'

  def self.batch_import(file, event, split_id_array)
    verify_split_id_array(split_id_array, event.course_id)
    spreadsheet = open_spreadsheet(file)
    header = spreadsheet.row(1)
    split_offset = header.map(&:downcase).index("start") + 1   # The column in which the Start split appears
    raise "Invalid header" if split_offset.nil?
    effort_offset = (spreadsheet.cell(2,1).downcase.include?("distance") && spreadsheet.cell(2,2).blank?) ? 3 : 2
    split_name_array = header[split_offset - 1..header.size - 1]
    if split_name_array.size != split_array.size
      raise "Number of split columns in import spreadsheet does not match number of selected course splits."
    else
      (effort_offset..spreadsheet.last_row).each do |i|
        create_effort(header, spreadsheet.row(i), event.id)
        create_split_times(spreadsheet.row(i), split_array, split_offset)
      end
    end
  end

  def self.verify_split_id_array(split_id_array, course_id)
    splits = []
    split_id_array.each do |id|
      @split = Split.find_by(id: id)
      raise "Split number #{split_id_array.index(id) + 1} was not found" if @split.nil?
      raise "Split number #{split_id_array.index(id) + 1} does not match course" if @split.course_id != course_id
      splits << @split
    end
    kind_array = splits.map(&:kind)
    kind_count_hash = kind_array.inject(Hash.new(0)) { |total, e| total[e] += 1 ;total}
    raise "Start split was not included in split id array" if kind_count_hash["start"] == 0
    raise "Multiple start splits included in split id array" if kind_count_hash["start"] > 1
    raise "Finish split was not included in split id array" if kind_count_hash["finish"] == 0
    raise "Multiple finish splits included in split id array" if kind_count_hash["finish"] > 1
    sorted_splits = splits.sort_by {|x| [x.distance_from_start, x.sub_order]}
    sorted_id_array = sorted_splits.map(&:id)
    raise "Incorrectly ordered split id array" if sorted_id_array != split_id_array
  end

  def self.open_spreadsheet(file)
    @spreadsheet_format = File.extname(file.original_filename)
    case @spreadsheet_format
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

  def create_effort (header, row, event_id)
    row_hash = Hash[[header, row].transpose].symbolize_keys
    # Would love to figure out how not to hardcode these symbols lists
    # (An array of symbols does not work)
    @effort = Effort.new(
        row_hash.slice(
            :first_name,
            :last_name,
            :gender,
            :birthdate,
            :email,
            :phone,
            :city,
            :state,
            :country,
            :age,
            :wave,
            :bib_number,
        )
    )
    @effort.event_id = event_id
    if @effort.save
      @effort
    else
      raise "Problem saving effort data for #{@participant.last_name}. #{@effort.errors.full_messages}."
    end
  end

  def create_split_times(row, split_array, split_offset)
    (split_offset..row.length).each do |k|
      working_split_id = split_array[k-split_offset]
      working_time = row[Split.find(working_split_id).name.to_sym]
      break if working_time.nil?
      if working_time.instance_of?(Date)
        working_time = working_time.in_time_zone # Converts Date to Datetime
      end
      if working_time.acts_like?(:time)
        working_time = datetime_to_seconds(working_time)
      end
      unless working_time.try(:to_f)
        raise "Invalid split time data for #{@participant.last_name} at #{Split.find_by_id(working_split_id).name}. #{@split_time.errors.full_messages}."
      end
      @split_time = @effort.split_times.new(
          split_id: working_split_id,
          time_from_start: working_time
      )
      if @split_time.save
      else
        raise "Problem saving split time data for #{@participant.last_name} at #{Split.find_by_id(working_split_id).name}. #{@split_time.errors.full_messages}."
      end
    end
  end

  # Corrects for Excel quirk; TODO: discover extent of this quirk
  #TODO: This will not work for datetimes that were intended as such
  def self.datetime_to_seconds(value)
    if (value.year < 1901) && @spreadsheet_format.include?("xls")
      value.seconds_since_midnight.to_f + 1.day
    else
      value.seconds_since_midnight.to_f
    end

  end

end