class EffortImporter
  extend ActiveModel::Naming

  attr_reader :errors, :effort_import_report, :effort_id_array, :effort_failure_array

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:file_path, :event, :current_user_id],
                           exclusive: [:file_path, :event, :current_user_id, :without_status],
                           class: self.class)
    @errors = ActiveModel::Errors.new(self)
    @import_file = ImportFile.new(args[:file_path])
    @event = args[:event]
    @current_user_id = args[:current_user_id]
    @without_status = args[:without_status]
    @sub_splits = event.sub_splits
    @effort_failure_array = []
    @effort_id_array = []
    @effort_schema = EffortSchema.new(header_column_titles)
  end

  def effort_import
    unless column_count_matches
      self.effort_import_report = 'Column count does not match'
      return
    end
    start_offset_hash = {}
    final_split_hash = {}
    (effort_offset..spreadsheet.last_row).each do |i|
      row = spreadsheet.row(i)
      row_effort_data = prepare_row_effort_data(row[0..split_offset - 2])
      effort = create_effort(row_effort_data)
      if effort
        row_time_data = row[split_offset - 1..row.size - 1]
        row_time_data.unshift(0) if finish_times_only?
        creator = EffortSplitTimeCreator.new(row_time_data, effort, current_user_id, event)
        creator.create_split_times
        start_offset_hash[effort.id] = creator.start_offset if creator.start_offset
        final_split_hash[effort.id] = creator.dropped_split_id
        effort_id_array << effort.id
      else
        effort_failure_array << row
      end
    end
    BulkUpdateService.bulk_update_start_offset(start_offset_hash)
    BulkUpdateService.bulk_update_dropped(final_split_hash)
    # Set data status on only those efforts that were successfully created
    BulkDataStatusSetter.set_data_status(efforts: event.efforts.find(effort_id_array)) unless without_status
    self.effort_import_report = EventReconcileService.auto_reconcile_efforts(event)
  end

  def effort_import_without_times
    self.import_without_times = true
    (effort_offset..spreadsheet.last_row).each do |i|
      row = spreadsheet.row(i)
      row_effort_data = prepare_row_effort_data(row)
      effort = create_effort(row_effort_data)
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
                :effort_schema, :import_without_times

  attr_reader :event, :current_user_id, :sub_splits, :without_status

  attr_writer :effort_import_report, :effort_id_array, :effort_failure_array

  delegate :spreadsheet, :header1, :header2, :split_offset, :effort_offset, :split_title_array, :finish_times_only?,
           :header1_downcase, to: :import_file

  def column_count_matches
    if (event_sub_split_count == 2) && ((split_title_array.size < 1) | (split_title_array.size > 2))
      errors.add(:effort_importer, "Your import file contains #{split_title_array.size} split time columns, " +
          "but this event expects only a finish time column with an optional start time column. " +
          "Please check your import file or create, remove, or associate splits as needed.")
      false
    elsif (event_sub_split_count > 2) && (split_title_array.size != event_sub_split_count)
      errors.add(:effort_importer, "Your import file contains #{split_title_array.size} split time columns, " +
          "but this event expects #{event_sub_split_count} columns. " +
          "Please check your import file or create, remove, or associate splits as needed.")
      false
    else
      true
    end
  end

  def create_effort(row_effort_data)
    effort = event.efforts.new
    row_effort_hash(row_effort_data).each { |attribute, data| effort.assign_attributes({attribute => data}) }
    effort.concealed = true if event.concealed?
    effort.save ? effort : nil
  end

  def row_effort_hash(row_effort_data)
    effort_schema.zip(row_effort_data).select { |title, data| title && data }.to_h
  end

  def prepare_row_effort_data(row_effort_data)
    EffortImportDataPreparer.new(row_effort_data, effort_schema.to_a).output_row
  end

  def event_sub_split_count
    sub_splits.count
  end

  def header_column_titles
    import_without_times ? header1 : header1[0..split_offset - 2]
  end

end