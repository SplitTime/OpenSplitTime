class EffortImporter
  extend ActiveModel::Naming

  attr_reader :errors, :effort_import_report, :effort_id_array, :effort_failure_array

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:file_path, :event, :current_user_id],
                           exclusive: [:file_path, :event, :current_user_id, :without_status],
                           class: self.class)
    @errors = ActiveModel::Errors.new(self)
    @import_file ||= ImportFile.new(args[:file_path])
    @event = args[:event]
    @current_user_id = args[:current_user_id]
    @without_status = args[:without_status]
    @effort_failure_array = []
    @effort_id_array = []
  end

  def effort_import
    unless column_count_matches?
      self.effort_import_report = 'Column count does not match'
      return
    end
    (effort_offset..spreadsheet.last_row).each do |i|
      row = spreadsheet.row(i)
      row_effort_data = prepare_row_effort_data(row[0...split_offset - 1])
      effort = create_or_update_effort(row_effort_data)
      if effort.errors.none?
        row_time_data = row[split_offset - 1...row.size]
        row_time_data.unshift(0) if finish_times_only?
        creator = EffortSplitTimeCreator.new(row_time_data: row_time_data, effort: effort,
                                             current_user_id: current_user_id, event: event)
        creator.create_split_times
        effort_id_array << effort.id
      else
        effort_failure_array << row
      end
    end
    set_drops_and_status
    self.effort_import_report = EventReconcileService.auto_reconcile_efforts(event)
  end

  def effort_import_military_times
    unless column_count_matches?
      self.effort_import_report = 'Column count does not match'
      return
    end
    (effort_offset..spreadsheet.last_row).each do |i|
      row = spreadsheet.row(i)
      row_effort_data = prepare_row_effort_data(row[0...split_offset - 1])
      effort = create_or_update_effort(row_effort_data)
      if effort
        row_time_data = row[split_offset - 1...row.size]
        creator = EffortSplitTimeCreator.new(row_time_data: row_time_data, effort: effort,
                                             current_user_id: current_user_id, event: event,
                                             military_times: true)
        creator.create_split_times
        effort_id_array << effort.id
      else
        effort_failure_array << row
      end
    end
    set_drops_and_status
    self.effort_import_report = EventReconcileService.auto_reconcile_efforts(event)
  end

  def effort_import_without_times
    self.import_without_times = true
    (effort_offset..spreadsheet.last_row).each do |i|
      row = spreadsheet.row(i)
      row_effort_data = prepare_row_effort_data(row)
      effort = create_or_update_effort(row_effort_data)
      if effort
        effort_id_array << effort.id
      else
        effort_failure_array << row
      end
    end
    self.effort_import_report = EventReconcileService.auto_reconcile_efforts(event)
  end

  # The following three methods are required for ActiveModel error reporting

  def read_attribute_for_validation(attr)
    send(attr)
  end

  def EffortImporter.human_attribute_name(attr)
    attr
  end

  def EffortImporter.lookup_ancestors
    [self]
  end

  private

  attr_accessor :import_file, :auto_matched_count, :participants_created_count, :unreconciled_efforts_count,
                :import_without_times
  attr_reader :event, :current_user_id, :without_status
  attr_writer :effort_import_report, :effort_id_array, :effort_failure_array
  delegate :spreadsheet, :header1, :header2, :split_offset, :effort_offset, :split_title_array, :finish_times_only?,
           :header1_downcase, to: :import_file
  delegate :laps_unlimited?, to: :event

  def column_count_matches?
    if laps_unlimited?
      true
    elsif (required_time_points_count == 2) && ((split_title_array.size < 1) | (split_title_array.size > 2))
      errors.add(:effort_importer, "Your import file contains #{split_title_array.size} split time columns, " +
          'but this event expects only a finish time column with an optional start time column. ' +
          'Please check your import file or create, remove, or associate splits as needed.')
      false
    elsif (required_time_points_count > 2) && (split_title_array.size != required_time_points_count)
      errors.add(:effort_importer, "Your import file contains #{split_title_array.size} split time columns, " +
          "but this event expects #{required_time_points_count} columns. " +
          'Please check your import file or create, remove, or associate splits as needed.')
      false
    else
      true
    end
  end

  def create_or_update_effort(row_effort_data)
    row_hash = row_effort_hash(row_effort_data)
    effort = Effort.find_or_initialize_by(event_id: event.id,
                                          bib_number: row_hash[:bib_number],
                                          first_name: row_hash[:first_name],
                                          last_name: row_hash[:last_name])
    row_hash.each { |attribute, data| effort.assign_attributes({attribute => data}) }
    effort.assign_attributes(created_by: current_user_id, updated_by: current_user_id, concealed: event.concealed?)
    effort.save
    effort
  end

  def set_drops_and_status
    DroppedAttributesSetter.set_attributes(efforts: imported_efforts)

    # Initial pass sets data_status based on the relaxed standards of the terrain model
    # Second pass sets data_status on the :stats model, ignoring times flagged as bad or questionable by the first pass
    unless without_status
      BulkDataStatusSetter.set_data_status(efforts: imported_efforts, calc_model: :terrain)
      BulkDataStatusSetter.set_data_status(efforts: imported_efforts, calc_model: :stats)
    end
  end

  def imported_efforts # Don't memoize--needs to be refreshed before the second pass
    event.efforts.where(id: effort_id_array)
  end

  def row_effort_hash(row_effort_data)
    effort_schema.zip(row_effort_data).select { |title, data| title && data }.to_h
  end

  def prepare_row_effort_data(row_effort_data)
    EffortImportDataPreparer.new(row_effort_data, effort_schema.to_a).output_row
  end

  def effort_schema
    @effort_schema ||= EffortSchema.new(header_column_titles)
  end

  def required_time_points
    @required_time_points ||= event.required_time_points
  end

  def required_time_points_count
    required_time_points.size
  end

  def header_column_titles
    import_without_times ? header1 : header1[0...split_offset - 1]
  end

  def military_times?
    @military_times
  end
end