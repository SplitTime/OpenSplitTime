class Importer
  require 'roo'

  def self.split_import(file, event)
    spreadsheet = open_spreadsheet(file)
    return false unless spreadsheet
    header1 = spreadsheet.row(1)
    header2 = spreadsheet.row(2)
    return false unless header1.size == header2.size # Split names and distances don't match up
    split_offset = compute_split_offset(header1)
    effort_offset = compute_effort_offset(header2)
    return false unless effort_offset == 3 # No split data detected
    distance_conversion_factor = compute_conversion_factor(header2[1])
    return false unless distance_conversion_factor
    split_array = header1[split_offset - 1..header1.size - 1]
    distance_array = header2[split_offset - 1..header2.size - 1]
    split_id_array = []
    error_array = []
    (0...split_array.size).each do |i|

      if i == 0 # First one, so find the existing start split or create a new one
        @split = event.course.start_split || Split.new(course_id: event.course_id,
                                                       name: 'Start',
                                                       distance_from_start: 0,
                                                       sub_order: 0,
                                                       kind: :start)

      elsif i == split_array.size - 1 # Last one, so find the existing finish split on the course
        @split = event.course.finish_split || Split.new(course_id: event.course_id,
                                                        name: split_array[i],
                                                        distance_from_start: (distance_array[i] * distance_conversion_factor),
                                                        sub_order: 0,
                                                        kind: :finish)

      else # This is not a start or finish, so set sub_order and create new split
        if distance_array[i-1] == distance_array[i]
          sub_order =+ 1
        else
          sub_order = 0
        end
        @split = Split.new(course_id: event.course_id,
                           name: split_array[i],
                           distance_from_start: (distance_array[i] * distance_conversion_factor),
                           sub_order: sub_order,
                           kind: :waypoint)

      end

      if @split.save
        split_id_array << @split.id
        event.splits << @split unless event.splits.include?(@split)
      else
        error_array << @split
      end
    end
    return split_id_array, error_array
  end

  def self.effort_import(file, event, current_user_id)
    spreadsheet = open_spreadsheet(file)
    return false unless spreadsheet
    header1 = spreadsheet.row(1).map { |cell| cell ? cell.downcase : nil }
    header2 = spreadsheet.row(2)

    split_offset = compute_split_offset(header1)
    split_name_array = header1[split_offset - 1..header1.size - 1]
    split_name_array = ["start", "finish"] if finish_times_only?(header1)
    split_id_array = event.ordered_split_ids
    if split_name_array.size != split_id_array.size
      raise "Number of split columns in import spreadsheet does not match number of selected course splits."
    end

    effort_offset = compute_effort_offset(header2)
    effort_name_array = header1[0..split_offset - 2]
    effort_symbols = Effort.columns_for_import
    effort_schema = build_effort_schema(effort_symbols, effort_name_array)

    effort_failure_array = []
    (effort_offset..spreadsheet.last_row).each do |i|
      row = spreadsheet.row(i)
      row_effort_data = prepare_row_effort_data(row[0..split_offset - 2], effort_schema)
      @effort = create_effort(row_effort_data, effort_schema, event)
      if @effort
        create_split_times(row, header1, split_id_array, split_offset, @effort, current_user_id)
        @effort.reset_time_from_start
      else
        effort_failure_array << row
      end
    end
    # TODO set data status of all efforts after import
    event.reconcile_exact_matches
    return effort_failure_array
  end

  private

  def self.prepare_row_effort_data(row_effort_data, effort_schema)
    i = effort_schema.index(:country_code)
    country_code = nil
    if i
      row_effort_data[i] = prepare_country_data(row_effort_data[i])
      country_code = row_effort_data[i]
    end
    i = effort_schema.index(:state_code)
    row_effort_data[i] = prepare_state_data(country_code, row_effort_data[i]) unless (i.nil? | country_code.nil?)
    i = effort_schema.index(:gender)
    row_effort_data[i] = prepare_gender_data(row_effort_data[i]) unless i.nil?
    i = effort_schema.index(:birthdate)
    row_effort_data[i] = prepare_birthdate_data(row_effort_data[i]) unless i.nil?
    row_effort_data
  end

  def self.prepare_country_data(country_data)
    return nil if country_data.blank?
    if country_data.is_a?(String)
      country_data = country_data.strip
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
    return nil if country_data.blank?
    country_code = I18n.t("nicknames.#{country_data.downcase}")
    country_code.include?('translation missing') ? nil : country_code
  end

  def self.prepare_state_data(country_code, state_data)
    return nil if state_data.blank?
    state_data = state_data.strip
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
    return nil if gender_data.blank?
    gender_data.downcase!
    gender_data = gender_data.strip
    return "male" if (gender_data == "m") | (gender_data == "male")
    return "female" if (gender_data == "f") | (gender_data == "female")
  end

  def self.prepare_birthdate_data(birthdate_data)
    return nil if birthdate_data.blank?
    return birthdate_data if birthdate_data.is_a?(Date)
    begin
      return Date.parse(birthdate_data) if birthdate_data.is_a?(String)
    rescue ArgumentError
      raise "Birthdate column includes invalid data"
    end
    return nil
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
    column_string.gsub!('bib', 'bibnumber')
    return (column_string == effort_string)
  end

  def self.open_spreadsheet(file)
    return nil unless file
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

  def self.finish_times_only?(header1)
    compute_split_offset(header1) == header1.size ? true : false
  end

  def self.compute_split_offset(header1)
    start_column_index = header1.map { |cell| cell ? cell.downcase : nil }.index("start")
    start_column_index ? start_column_index + 1 : header1.size
  end

  def self.compute_effort_offset(header2)
    unit_array = %w[miles meters km kilometers]
    header2[0].downcase.include?("distance") &&
        (header2[1].blank? || unit_array.include?(header2[1])) ? 3 : 2
  end

  def self.compute_conversion_factor(units)
    units ||= ""
    x = case units.downcase
          when "km"
            1.kilometers.to.meters.value
          when "kilometers"
            1.kilometers.to.meters.value
          when "meters"
            1
          when "miles"
            1.miles.to.meters.value
          when "" # Assume miles if no unit is indicated
            1.miles.to.meters.value
          else
            false
        end
    x ? x.to_f : false
  end

  def self.create_effort (row_effort_data, effort_schema, event)
    @effort = event.efforts.new
    (0...effort_schema.size).each do |i|
      @effort.assign_attributes({effort_schema[i] => row_effort_data[i]}) unless effort_schema[i].nil?
    end
    if @effort.save
      @effort
    else
      nil
    end
  end

  def self.create_split_times(row, header1, split_array, split_offset, effort, current_user_id)
    row_time_data = row[split_offset - 1..row.size - 1]
    row_time_data = [0] + row_time_data if finish_times_only?(header1)
    return nil if split_array.size != row_time_data.size
    SplitTime.bulk_insert(:effort_id, :split_id, :time_from_start, :created_at, :updated_at, :created_by, :updated_by) do |worker|
      (0...split_array.size).each do |i|
        split_id = split_array[i]
        working_time = row_time_data[i]
        working_time ||= 0 if i == 0 # Make sure start_splits are never nil
        seconds = convert_time_to_standard(working_time)
        if i == split_array.size - 1
          effort.update(dropped: seconds.nil? ? true : false)
        end
        next if seconds.nil?
        worker.add(effort_id: effort.id,
                   split_id: split_id,
                   time_from_start: seconds,
                   created_by: current_user_id,
                   updated_by: current_user_id)
      end
    end
  end

  def self.convert_time_to_standard(working_time)
    return nil if working_time.blank?
    working_time = working_time.to_datetime if working_time.instance_of?(Date) # Converts date to datetime
    working_time = datetime_to_seconds(working_time) if working_time.acts_like?(:time)
    if working_time.try(:to_f)
      working_time
    else
      nil # raise "Invalid split time data for #{effort.last_name}. #{errors.full_messages}."
    end
  end

  def self.datetime_to_seconds(value)
    if (value.year < 1901) && @spreadsheet_format.include?("xls")
      TimeDifference.between(value, "1899-12-30".to_datetime).in_seconds
    else
      value.seconds_since_midnight.to_f
    end
  end

end