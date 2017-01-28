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
        set_dropped_attributes(effort_data)
      else
        unsaved_rows << effort_data.response_row
      end
    end
  end

  def returned_rows
    {returnedRows: unsaved_rows}
  end

  private

  EXTRACTABLE_ATTRIBUTES = %w(time_from_start data_status pacer remarks)

  attr_reader :event, :time_rows, :times_container
  attr_accessor :unsaved_rows

  # Returns true if all available times (in or out or both) are created/updated.
  # Returns false if any create/update is attempted but rejected

  def create_or_update_times(effort_data)
    indexed_split_times = effort_data.indexed_existing_split_times
    split_time_ids = []

    effort_data.proposed_split_times.each do |proposed_split_time|
      working_split_time = indexed_split_times[proposed_split_time.time_point] || proposed_split_time
      saved_split_time_id = create_or_update_split_time(proposed_split_time, working_split_time)
      split_time_ids << saved_split_time_id
    end

    FollowerMailerService.send_live_effort_mail(effort_data.participant_id, split_time_ids)
    split_time_ids.exclude?(nil)
  end

  def set_dropped_attributes(effort_data)
    effort = effort_data.effort
    dropped_here_key = effort_data.dropped_here? ? effort_data.subject_lap_split.key : nil
    if dropped_here_key || (effort.dropped_key == effort_data.subject_lap_split.key)
      effort.dropped_key = dropped_here_key # Undrops the effort if dropped_here_key is nil
      effort.save if effort.changed?
      EffortDataStatusSetter.set_data_status(effort: effort, times_container: times_container)
    end
  end

  def create_or_update_split_time(proposed_split_time, working_split_time)
    working_split_time.id if working_split_time.update(extracted_attributes(proposed_split_time))
  end

  def extracted_attributes(split_time)
    split_time.attributes.select { |attribute, _| EXTRACTABLE_ATTRIBUTES.include?(attribute) }
  end

  def ordered_splits
    @ordered_splits ||= event.ordered_splits.to_a
  end

  def force_option?
    time_rows.size == 1
  end
end