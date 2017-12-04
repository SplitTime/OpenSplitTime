class EffortImporter
  extend ActiveModel::Naming
  include BackgroundNotifiable

  attr_reader :effort_import_report, :effort_id_array, :effort_failure_array

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:file_path, :event, :current_user_id],
                           exclusive: [:file_path, :event, :current_user_id, :with_status,
                                       :with_times, :time_format, :background_channel],
                           class: self.class)
    @import_file ||= ImportFile.new(args[:file_path])
    @event = args[:event]
    @current_user_id = args[:current_user_id]
    @with_status ||= (args[:with_status] || 'true').to_boolean
    @with_times ||= (args[:with_times] || 'true').to_boolean
    @time_format ||= args[:time_format] || 'elapsed'
    @background_channel = args[:background_channel]
    @effort_failure_array = []
    @effort_id_array = []
  end

  def effort_import
    if with_times
      unless column_count_matches?
        self.effort_import_report = 'Column count does not match'
        report_error(message: event.errors.full_messages)
        return
      end
    end
    total_efforts = spreadsheet.last_row - effort_offset + 1
    (effort_offset..spreadsheet.last_row).each do |i|
      row = spreadsheet.row(i)
      row_effort_data = prepare_row_effort_data(non_time_data(row))
      effort = create_or_update_effort(row_effort_data)
      if effort.errors.none?
        create_split_times(effort, row) if with_times
        effort_id_array << effort.id
      else
        effort_failure_array << {data: row, errors: effort.errors.full_messages}
      end
      current_effort = i - effort_offset + 1
      report_progress(action: 'imported', resource: 'effort', current: current_effort, total: total_efforts)
    end
    set_drops_and_status
    report_status(message: "Reconciling #{total_efforts} efforts...")
    self.effort_import_report = EffortAutoReconciler.reconcile(event: event)
    report_status(message: "Reconciling #{total_efforts} efforts...done")
  end

  def errors
    event.errors
  end

  private

  attr_accessor :import_file, :auto_matched_count, :people_created_count, :unreconciled_efforts_count
  attr_reader :event, :current_user_id, :with_status, :with_times, :time_format, :background_channel
  attr_writer :effort_import_report
  delegate :spreadsheet, :header1, :header2, :split_offset, :effort_offset, :split_title_array, :finish_times_only?,
           :header1_downcase, to: :import_file
  delegate :laps_unlimited?, to: :event

  def column_count_matches?
    if laps_unlimited?
      true
    elsif (required_time_points_count == 2) && ((split_title_array.size < 1) | (split_title_array.size > 2))
      event.errors.add(:effort_importer, "Your import file contains #{split_title_array.size} split time columns, " +
          'but this event expects only a finish time column with an optional start time column. ' +
          'Please check your import file or create, remove, or associate splits as needed.')
      false
    elsif (required_time_points_count > 2) && (split_title_array.size != required_time_points_count)
      event.errors.add(:effort_importer, "Your import file contains #{split_title_array.size} split time columns, " +
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
    row_hash.each {|attribute, data| effort.assign_attributes({attribute => data})}
    effort.assign_attributes(created_by: current_user_id, updated_by: current_user_id)
    effort.save
    effort
  end

  def create_split_times(effort, row)
    row_time_data = row[split_offset - 1...row.size]
    row_time_data.unshift(0) if finish_times_only? && (time_format == 'elapsed')
    creator = EffortSplitTimeCreator.new(row_time_data: row_time_data, effort: effort,
                                         current_user_id: current_user_id, event: event,
                                         time_format: time_format)
    creator.create_split_times
  end

  def set_drops_and_status
    Interactors::UpdateEffortsStop.perform!(imported_efforts, true)

    # Initial pass sets data_status based on the relaxed standards of the terrain model
    # Second pass sets data_status on the :stats model, ignoring times flagged as bad or questionable by the first pass
    if with_status
      BulkDataStatusSetter.set_data_status(efforts: imported_efforts, calc_model: :terrain, background_channel: background_channel)
      BulkDataStatusSetter.set_data_status(efforts: imported_efforts, calc_model: :stats, background_channel: background_channel)
    end
  end

  def imported_efforts # Don't memoize--needs to be refreshed before the second pass
    event.efforts.where(id: effort_id_array)
  end

  def row_effort_hash(row_effort_data)
    effort_schema.zip(row_effort_data).select {|title, data| title && data}.to_h
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
    non_time_data(header1)
  end

  def non_time_data(row)
    with_times ? row[0...split_offset - 1] : row
  end

  def military_times?
    @military_times
  end
end
