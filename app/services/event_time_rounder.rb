# When events are imported from an .xls or .xlsx file, time_from_start for some split_times
# may be off by :01 in either direction as a result of rounding problems in Excel.
# EventTimeRounder.fix_excel_import corrects for these rounding errors.
# This class modifies only intermediate times unless args[:finish_times] == true.

class EventTimeRounder
  def self.fix_excel_import(args)
    rounder = new(args)
    rounder.fix_excel_import
    rounder.save_changes
    rounder.report
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required_alternatives: [:event, :event_id],
                           exclusive: [:event, :event_id],
                           class: self.class)
    @event = args[:event] || Event.friendly.find(args[:event_id])
    @finish_times = args[:finish_times]
    @reports = []
  end

  def fix_excel_import
    Rails.logger.info "Found #{targeted_split_times.size} split times that need rounding for #{event.name}"
    targeted_split_times.each { |st| st.time_from_start = st.time_from_start.round_to_nearest(1.minute) }
  end

  def save_changes
    saved_records_count = 0
    targeted_split_times.each do |st|
      if st.save
        saved_records_count += 1
      else
        reports << st.errors.full_messages
      end
    end
    reports.unshift("Fixed #{saved_records_count} split_times")
  end

  def report
    reports.join(' / ')
  end

  private

  attr_reader :event, :finish_times, :reports

  def targeted_split_times
    @targeted_split_times ||=
        scoped_split_times.where('mod(cast(split_times.time_from_start as integer), 60) IN (1, 59)')
  end

  def scoped_split_times
    finish_times ? event.split_times.int_and_finish : event.split_times.intermediate
  end
end