class Importer
  require 'roo'

  def self.split_import(file, event)
    spreadsheet = open_spreadsheet(file)
    split_offset, effort_offset = compute_offsets(spreadsheet)
    return false unless effort_offset == 3 # No split data detected
    header1 = spreadsheet.row(1)
    header2 = spreadsheet.row(2)
    distance_units = header2[1]
    return false unless header1.size == header2.size # Split names and distances don't match up
    split_array = header1[split_offset - 1..header1.size - 1]
    distance_array = header2[split_offset - 1..header2.size - 1]
    split_id_array = []
    error_array = []
    (0..split_array.size - 1).each do |i|
      if i == 0 # First split is always kind = start and sub_order = 0
        kind = :start
        sub_order = 0
      else # Otherwise determine kind and sub_order
        kind = i == split_array.size - 1 ? :finish : :waypoint
        if distance_array[i-1] == distance_array[i]
          sub_order =+1
        else
          sub_order = 0
        end
      end
      name = split_array[i]
      distance = convert_to_meters(distance_array[i], distance_units)

      split = Split.new(course_id: event.course_id,
                        name: name,
                        distance_from_start: distance,
                        sub_order: sub_order,
                        kind: kind)
      if split.save
        split_id_array << split.id
        event.splits << split
      else
        error_array << split
      end
    end
    return split_id_array, error_array
  end

  def self.effort_import(file, event)
    effort_symbols = Effort.columns_for_import
    spreadsheet = open_spreadsheet(file)
    split_offset, effort_offset = compute_offsets(spreadsheet)
    header = spreadsheet.row(1)

    effort_name_array = header[0..split_offset - 2]
    effort_schema = build_effort_schema(effort_symbols, effort_name_array)

    split_name_array = header[split_offset - 1..header.size - 1]
    split_id_array = event.split_id_array
    if split_name_array.size != split_id_array.size
      raise "Number of split columns in import spreadsheet does not match number of selected course splits."
    end

    effort_failure_array = []
    (effort_offset..spreadsheet.last_row).each do |i|
      row = spreadsheet.row(i)
      row_effort_data = prepare_row_effort_data(row[0..split_offset - 2], effort_schema)
      @effort = create_effort(row_effort_data, effort_schema, event)
      if @effort
        create_split_times(row, split_id_array, split_offset, @effort)
      else
        effort_failure_array << row
      end
    end
    return effort_failure_array
  end

  private

  def self.prepare_row_effort_data(row_effort_data, effort_schema)
    i = effort_schema.index(:country_code)
    row_effort_data[i] = prepare_country_data(row_effort_data[i]) unless i.nil?
    country_code = row_effort_data[i]
    i = effort_schema.index(:state_code)
    row_effort_data[i] = prepare_state_data(country_code, row_effort_data[i]) unless (i.nil? | country_code.nil?)
    i = effort_schema.index(:gender)
    row_effort_data[i] = prepare_gender_data(row_effort_data[i]) unless i.nil?
    row_effort_data
  end

  def self.prepare_country_data(country_data)
    if country_data.is_a?(String)
      if country_data.length < 4
        country = Carmen::Country.coded(country_data)
        return country.code unless country.nil?
      end
      country = Carmen::Country.named(country_data)
      return country.code unless country.nil?
      return find_country_code_by_nickname(country_data)
    else
      return nil
    end
  end

  def self.find_country_code_by_nickname(country_data)
    country_code = I18n.t("nicknames.#{country_data.downcase}")
    country_code.include?('translation missing') ? nil : country_code
  end

  def self.prepare_state_data(country_code, state_data)
    country = Carmen::Country.coded(country_code)
    if state_data.is_a?(String)
      return state_data if country.nil?
      return state_data unless country.subregions?
      if state_data.length < 4
        subregion = country.subregions.coded(state_data)
        return subregion.code unless subregion.nil?
      end
      subregion = country.subregions.named(state_data)
      return subregion.code unless subregion.nil?
    end
    return nil
  end

  def self.prepare_gender_data(gender_data)
    gender_data.downcase!
    return "male" if (gender_data == "m") | (gender_data == "male")
    return "female" if (gender_data == "f") | (gender_data == "female")
  end

# Returns an array of effort symbols in order of spreadsheet columns
# with nil placeholders for spreadsheet columns that don't match

  def self.build_effort_schema(effort_symbols, effort_name_array)
    schema = []
    effort_name_array.each do |column_title|
      schema << get_closest_effort_symbol(column_title, effort_symbols)
    end
    schema
  end

  def self.get_closest_effort_symbol(column_title, effort_symbols)
    effort_symbols.each do |effort_symbol|
      return effort_symbol if fuzzy_match(column_title, effort_symbol)
    end
    return nil
  end

  def self.fuzzy_match(column_title, effort_symbol)
    effort_string = effort_symbol.to_s.downcase.gsub(/[\W_]+/, '')
    effort_string.gsub!('countrycode', 'country')
    effort_string.gsub!('statecode', 'state')
    column_string = column_title.downcase.gsub(/[\W_]+/, '')
    column_string.gsub!('nation', 'country')
    column_string.gsub!('region', 'state')
    column_string.gsub!('province', 'state')
    column_string.gsub!('sex', 'gender')
    return (column_string == effort_string)
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

  def self.compute_offsets(spreadsheet)
    header = spreadsheet.row(1)
    split_offset = header.map(&:downcase).index("start") + 1
    key_cell = spreadsheet.cell(2, 2)
    unit_array = %w[miles meters km kilometers]
    effort_offset = (spreadsheet.cell(2, 1).downcase.include?("distance") &&
        (key_cell.blank? || unit_array.include?(key_cell))) ? 3 : 2
    return split_offset, effort_offset
  end

  def self.convert_to_meters(value, units)
    units ||= ""
    x = case units.downcase
          when "km"
            value.kilimeters.to.meters
          when "kilometers"
            value.kilometers.to.meters
          when "meters"
            value
          when "miles"
            value.miles.to.meters
          when "" # Assume miles
            value.miles.to.meters
          else
            false
        end
    x ? x.to_i : false
  end

  def self.create_effort (row_effort_data, effort_schema, event)
    @effort = event.efforts.new(start_time: event.first_start_time)
    (0..effort_schema.size - 1).each do |i|
      @effort.assign_attributes({effort_schema[i] => row_effort_data[i]}) unless effort_schema[i].nil?
    end
    if @effort.save
      @effort
    else
      nil
    end
  end

  def self.create_split_times(row, split_array, split_offset, effort)
    row_time_data = row[split_offset - 1..row.size - 1]
    return nil if split_array.size != row_time_data.size
    split_time_id_array = []
    (0..split_array.size - 1).each do |i|
      working_split_id = split_array[i]
      working_time = row_time_data[i]
      seconds = convert_time_to_standard(working_time)
      if seconds.nil?
        effort.update_attributes(finished: false) if i == split_array.size - 1
        next
      else
        @split_time = effort.split_times.new(split_id: working_split_id,
                                             time_from_start: seconds)
      end
      if @split_time.save
        split_time_id_array << @split_time.id
        effort.update_attributes(finished: true) if i == split_array.size - 1
      else
        raise "Problem saving split time data for #{@effort.last_name} at #{Split.find_by_id(working_split_id).name}. #{@split_time.errors.full_messages}."
      end
    end
    split_time_id_array
  end

  def self.convert_time_to_standard(working_time)
    return nil if working_time.blank?
    if working_time.instance_of?(Date)
      working_time = working_time.in_time_zone # Converts Date to Datetime
    end
    if working_time.acts_like?(:time)
      working_time = datetime_to_seconds(working_time)
    end
    if working_time.try(:to_f)
      working_time
    else
      nil # raise "Invalid split time data for #{effort.last_name}. #{errors.full_messages}."
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