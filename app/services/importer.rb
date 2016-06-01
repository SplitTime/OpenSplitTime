class Importer
  require 'roo'
  extend ActiveModel::Naming

  attr_accessor :split_import_report, :effort_import_report, :split_id_array, :effort_id_array,
                :split_failure_array, :effort_failure_array, :importer
  attr_reader :errors, :event, :current_user_id

  def initialize(file, event, current_user_id)
    @errors = ActiveModel::Errors.new(self)
    @spreadsheet = open_spreadsheet(file)
    return false unless spreadsheet
    @header1 = spreadsheet.row(1)
    @header2 = spreadsheet.row(2)
    @event = event
    @current_user_id = current_user_id
  end

  def split_import
    return false unless header1.size == header2.size # Split names and distances don't match up
    return false unless effort_offset == 3 # No split data detected
    self.distance_conversion_factor = conversion_factor(header2[1])
    return false unless distance_conversion_factor
    self.split_id_array = []
    self.split_failure_array = []
    self.running_sub_split_bitkey = 1
    (0...split_title_array.size).each do |i|
      split = create_split(i)
      if split.save
        split_id_array << split.id
        event.splits << split unless event.splits.include?(split)
        self.most_recent_saved_split = split
      else
        split_failure_array << split
      end
      self.running_sub_split_bitkey = (distance_array[i] == distance_array[i + 1]) ?
          SubSplit.next_bitkey(running_sub_split_bitkey) : 1
    end
  end

  def effort_import
    self.sub_split_bitkey_hashes = event.sub_split_bitkey_hashes
    if split_name_array.size != sub_split_bitkey_hashes.size
      errors.add(:importer, "Your import file contains #{split_name_array.size} split time columns, but this event expects #{sub_split_bitkey_hashes.size} columns. Please check your import file or create, remove, or associate splits as needed.")
      return
    end
    build_effort_schema
    self.effort_failure_array = []
    self.effort_id_array = []
    start_offset_hash = {}
    final_split_hash = {}
    (effort_offset..spreadsheet.last_row).each do |i|
      row = spreadsheet.row(i)
      row_effort_data = prepare_row_effort_data(row[0..split_offset - 2])
      @effort = create_effort(row_effort_data)
      if @effort
        start_offset, final_split = create_split_times(row, @effort.id)
        start_offset_hash[@effort.id] = start_offset if start_offset
        final_split_hash[@effort.id] = final_split
        effort_id_array << @effort.id
      else
        effort_failure_array << row
      end
    end
    BulkUpdateService.bulk_update_start_offset(start_offset_hash)
    BulkUpdateService.bulk_update_dropped(final_split_hash)
    # DataStatusService.set_data_status(event.efforts)
    self.auto_matched_count, self.participants_created_count =
        EventReconcileService.auto_reconcile_efforts(event)
    create_effort_import_report
  end

  # The following three methods are required for ActiveModel error reporting

  def read_attribute_for_validation(attr)
    send(attr)
  end

  def Importer.human_attribute_name(attr)
    attr
  end

  def Importer.lookup_ancestors
    [self]
  end

  private

  attr_accessor :spreadsheet, :auto_matched_count, :participants_created_count, :unreconciled_efforts_count,
                :effort_schema, :header1, :header2, :distance_conversion_factor, :split_id_array,
                :running_sub_split_bitkey, :most_recent_saved_split, :sub_split_bitkey_hashes

  def create_effort_import_report
    self.effort_import_report = ""
    self.unreconciled_efforts_count = event.unreconciled_efforts.count

    if auto_matched_count > 0
      self.effort_import_report += "We found #{auto_matched_count} participants that matched our database. "
    else
      self.effort_import_report += "No participants matched our database exactly. "
    end

    if participants_created_count > 0
      self.effort_import_report += "We created #{participants_created_count} participants from efforts that had no close matches. "
    end

    if unreconciled_efforts_count > 0
      self.effort_import_report += "We found #{unreconciled_efforts_count} participants that may or may not match our database. Please reconcile them now. "
    else
      self.effort_import_report += "All efforts for #{event.name} have been reconciled. "
    end
  end

  def create_split(i)
    if i == 0 # First one, so find the existing start split or create a new one
      split = event.course.start_split || Split.new(course_id: event.course_id,
                                                    base_name: 'Start',
                                                    distance_from_start: 0,
                                                    sub_split_bitmap: 1, # Start splits have 'in' only
                                                    kind: :start)

    elsif i == split_title_array.size - 1 # Last one, so find the existing finish split or create a new one
      split = event.course.finish_split || Split.new(course_id: event.course_id,
                                                     base_name: split_title_array[i],
                                                     distance_from_start: (distance_array[i] * distance_conversion_factor),
                                                     sub_split_bitmap: 1, # Finish splits have 'in' only
                                                     kind: :finish)

    else # This is not a start or finish, so check running sub_split. If == 1, make a new split.
      # Otherwise update the sub_split_bitmap
      base_name, name_extension = base_name_and_extension(split_title_array[i])
      if running_sub_split_bitkey == 1
        split = Split.new(course_id: event.course_id,
                          base_name: base_name,
                          distance_from_start: (distance_array[i] * distance_conversion_factor),
                          sub_split_bitmap: 1,
                          kind: :intermediate)
      else
        split = most_recent_saved_split
        sub_split_bitkey = [SubSplit.bitkey(name_extension), running_sub_split_bitkey].compact.max
        split.sub_split_bitmap = (split.sub_split_bitmap | sub_split_bitkey)
        self.running_sub_split_bitkey = [sub_split_bitkey, running_sub_split_bitkey].max
      end

    end
    split
  end

  def create_effort(row_effort_data)
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

  # Creates split_times for each valid time entry in the provided row
  # and returns the start_offset (if the first time entry is non-zero)
  # and the dropped_split_id (if there is no valid finish time)

  def create_split_times(row, effort_id)
    row_time_data = row[split_offset - 1..row.size - 1]
    row_time_data.unshift(0) if finish_times_only?
    return nil if sub_split_bitkey_hashes.size != row_time_data.size
    dropped_split_pointer = start_offset = nil
    finish_bitkey_hash = sub_split_bitkey_hashes.last

    SplitTime.bulk_insert(:effort_id, :split_id, :sub_split_bitkey, :time_from_start, :created_at, :updated_at, :created_by, :updated_by) do |worker|
      (0...sub_split_bitkey_hashes.count).each do |i|
        bitkey_hash = sub_split_bitkey_hashes[i]
        split_id = bitkey_hash.keys.first
        sub_split_bitkey = bitkey_hash.values.first
        working_time = row_time_data[i]

        # If this is the first (start) column, set start_offset
        # from non-zero start split time and reset start split time to zero

        if i == 0
          start_offset = working_time || 0
          working_time = 0
        end

        seconds = convert_time_to_standard(working_time)

        # If no valid time is present, go to next without creating a split_time
        # and without updating the dropped_split_pointer

        next if seconds.nil?
        worker.add(effort_id: effort_id,
                   split_id: split_id,
                   sub_split_bitkey: sub_split_bitkey,
                   time_from_start: seconds,
                   created_by: current_user_id,
                   updated_by: current_user_id)
        dropped_split_pointer = (bitkey_hash == finish_bitkey_hash) ? nil : split_id
      end
    end
    [start_offset, dropped_split_pointer]
  end

  def open_spreadsheet(file)
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

  # This method and the several that follow analyze the import data
  # and attempt to conform it to the database schema

  def prepare_row_effort_data(row_effort_data)
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

  def prepare_country_data(country_data)
    return nil if country_data.blank?
    if country_data.is_a?(String)
      country_data = country_data.strip
      if country_data.length < 4
        country = Carmen::Country.coded(country_data)
        return country.code unless country.nil?
      end
      country = Carmen::Country.named(country_data)
      return country.code unless country.nil?
      find_country_code_by_nickname(country_data)
    else
      nil
    end
  end

  def find_country_code_by_nickname(country_data)
    return nil if country_data.blank?
    country_code = I18n.t("nicknames.#{country_data.downcase}")
    country_code.include?('translation missing') ? nil : country_code
  end

  def prepare_state_data(country_code, state_data)
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
    nil
  end

  def prepare_gender_data(gender_data)
    return nil if gender_data.blank?
    gender_data.downcase!
    gender_data = gender_data.strip
    return "male" if (gender_data == "m") | (gender_data == "male")
    return "female" if (gender_data == "f") | (gender_data == "female")
  end

  def prepare_birthdate_data(birthdate_data)
    return nil if birthdate_data.blank?
    return birthdate_data if birthdate_data.is_a?(Date)
    begin
      return Date.parse(birthdate_data) if birthdate_data.is_a?(String)
    rescue ArgumentError
      raise "Birthdate column includes invalid data"
    end
    nil
  end

  # build_effort_schema and related methods return
  # an array of symbols representing attributes of the effort model.
  # Symbols are returned in order of the spreadsheet columns
  # with nil placeholders for spreadsheet columns that don't match
  # any importable effort attribute

  def build_effort_schema
    header_column_titles = header1[0..split_offset - 2]
    effort_attributes = Effort.attributes_for_import
    self.effort_schema = []
    header_column_titles.each do |column_title|
      matching_attribute = get_closest_effort_attribute(column_title, effort_attributes)
      effort_schema << matching_attribute
    end
  end

  def get_closest_effort_attribute(column_title, effort_attributes)
    effort_attributes.each do |effort_attribute|
      return effort_attribute if fuzzy_match(column_title, effort_attribute)
    end
    nil
  end

  def fuzzy_match(column_title, effort_attribute)
    attribute_string = effort_attribute.to_s.downcase.gsub(/[\W_]+/, '')
    attribute_string.gsub!('countrycode', 'country')
    attribute_string.gsub!('statecode', 'state')
    attribute_string.gsub!('bibnumber', 'bib')
    column_string = column_title.downcase.gsub(/[\W_]+/, '')
    column_string.gsub!('nation', 'country')
    column_string.gsub!('region', 'state')
    column_string.gsub!('province', 'state')
    column_string.gsub!('sex', 'gender')
    column_string.gsub!('bibnumber', 'bib')
    column_string.gsub!('bibno', 'bib')
    (column_string == attribute_string)
  end

  def finish_times_only?
    split_offset == header1.size
  end

  def split_offset
    start_column_index = header1_downcase.index("start")
    start_column_index ? start_column_index + 1 : header1.size
  end

  def effort_offset
    unit_array = %w[miles meters km kilometers]
    header2[0].downcase.include?("distance") &&
        (header2[1].blank? || unit_array.include?(header2[1])) ? 3 : 2
  end

  def header1_downcase
    header1.map { |cell| cell ? cell.downcase : nil }
  end

  def split_title_array
    header1[split_offset - 1..header1.size - 1]
  end

  def distance_array
    header2[split_offset - 1..header2.size - 1]
  end

  def split_name_array
    finish_times_only? ? ["start", "finish"] : split_title_array
  end

  def conversion_factor(units)
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

  def convert_time_to_standard(working_time)
    return nil if working_time.blank?
    working_time = working_time.to_datetime if working_time.instance_of?(Date)
    working_time = datetime_to_seconds(working_time) if working_time.acts_like?(:time)
    if working_time.try(:to_f)
      working_time
    else
      errors.add(:importer, "Invalid split time data for #{effort.last_name}. #{errors.full_messages}.")
    end
  end

  def datetime_to_seconds(value)
    if (value.year < 1910) && @spreadsheet_format.include?("xls")
      TimeDifference.between(value, "1899-12-30".to_datetime).in_seconds
    else
      TimeDifference.between(value, event.start_time).in_seconds
    end
  end

  def base_name_and_extension(split_name)
    base_name = split_name.split.reject { |x| (x.downcase == 'in') | (x.downcase == 'out') }.join(' ')
    name_extension = split_name.gsub(base_name, '').strip
    [base_name, name_extension]
  end

end