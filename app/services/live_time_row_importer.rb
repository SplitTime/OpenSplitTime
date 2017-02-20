class LiveTimeRowImporter

  def self.import(args)
    importer = new(args)
    importer.import
    importer.returned_rows
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:event, :time_rows],
                           exclusive: [:event, :time_rows],
                           class: self.class)
    @event = args[:event]
    @time_rows = args[:time_rows].map(&:last) # time_row.first is a unneeded id; time_row.last contains all needed data
    @times_container = SegmentTimesContainer.new(calc_model: :stats)
    @unsaved_rows = []
    @saved_split_times = []
  end

  def import
    time_rows.each do |time_row|
      effort_data = NewLiveEffortData.new(event: event,
                                          params: time_row,
                                          ordered_splits: ordered_splits,
                                          times_container: times_container)

      # If just one row was submitted, assume the user has noticed if data status is bad or questionable,
      # or if times will be overwritten, so call bulk_create_or_update with force option. If more than one
      # row was submitted, call bulk_create_or_update without force option.

      if effort_data.valid? && (effort_data.clean? || force_option?) && create_or_update_times(effort_data)
        adjust_later_times(effort_data.effort)
        set_dropped_attributes(effort_data)
      end
    end
  end

  def returned_rows
    {returnedRows: unsaved_rows}
  end

  private

  EXTRACTABLE_ATTRIBUTES = %w(time_from_start data_status pacer remarks stopped_here)

  attr_reader :event, :time_rows, :times_container
  attr_accessor :unsaved_rows, :saved_split_times

  # Returns true if all available times (in or out or both) are created/updated.
  # Returns false if any create/update is attempted but rejected

  def create_or_update_times(effort_data)
    effort = effort_data.effort
    indexed_split_times = effort_data.indexed_existing_split_times
    row_split_time_ids = []
    row_success = true

    effort_data.proposed_split_times.each do |proposed_split_time|
      working_split_time = indexed_split_times[proposed_split_time.time_point] || proposed_split_time
      saved_split_time = create_or_update_split_time(proposed_split_time, working_split_time)
      if saved_split_time
        make_stop_exclusive(effort, saved_split_time) if saved_split_time.stopped_here
        saved_split_times << saved_split_time
        row_split_time_ids << saved_split_time.id
      else
        unsaved_rows << effort_data.response_row
        row_success = false
      end
    end

    EffortDataStatusSetter.set_data_status(effort: effort, times_container: times_container)
    FollowerMailerService.send_live_effort_mail(effort_data.participant_id, row_split_time_ids) if row_success
    row_success
  end

  def make_stop_exclusive(effort, split_time)
    effort.split_times.each do |st|
      st.assign_attributes(stopped_here: false) unless st.time_point == split_time.time_point
      st.save if st.changed?
    end
  end

  # Live time data is entered based on military time, and we should assume the military time
  # (as opposed to the elapsed time stored in the database) is more likely correct if the
  # two conflict. Therefore, if an effort.start_offset changes by virtue of entering a
  # different start split time, assume we need to counter that change in all later split_times
  # for that effort, if any.

  def adjust_later_times(effort)
    start_offset_shift = effort.start_offset - effort.start_offset_was
    return if start_offset_shift.zero?
    split_times = effort.split_times.to_a.reject { |st| st.time_from_start.zero? }
    split_times.each do |st|
      if st.update(time_from_start: st.time_from_start - start_offset_shift)
        puts "updating split_time #{st.id} time_from_start by #{-start_offset_shift} seconds to counteract " +
                 "change in start_offset of effort #{effort.id} from #{effort.start_offset_was} to #{effort.start_offset}"
      else
        puts "failed to update split_time #{st.id} for the following reasons: #{st.errors.full_messages}"
      end
    end
    effort.save
  end

  def set_dropped_attributes(effort_data)
    effort = effort_data.effort
    dropped_here_key = effort_data.stopped_here? ? effort_data.subject_lap_split.key : nil
    if dropped_here_key || (effort.dropped_key == effort_data.subject_lap_split.key)
      effort.dropped_key = dropped_here_key # Undrops the effort if dropped_here_key is nil
      effort.save if effort.changed?
      EffortDataStatusSetter.set_data_status(effort: effort, times_container: times_container)
    end
  end

  def create_or_update_split_time(proposed_split_time, working_split_time)
    working_split_time if working_split_time.update(extracted_attributes(proposed_split_time))
  end

  # Extract only those extractable attributes that are non-nil (false must be extracted)
  def extracted_attributes(split_time)
    split_time.attributes.select { |attribute, value| EXTRACTABLE_ATTRIBUTES.include?(attribute) && !value.nil? }
  end

  def ordered_splits
    @ordered_splits ||= event.ordered_splits.to_a
  end

  def force_option?
    time_rows.size == 1
  end
end