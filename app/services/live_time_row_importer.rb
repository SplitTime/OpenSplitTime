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
    @times_container ||= SegmentTimesContainer.new(calc_model: :stats)
    @unsaved_rows = []
    @saved_split_times = []
  end

  def import
    time_rows.each do |time_row|
      effort_data = LiveEffortData.new(event: event,
                                       params: time_row,
                                       ordered_splits: ordered_splits,
                                       times_container: times_container)

      # If just one row was submitted, assume the user has noticed if data status is bad or questionable,
      # or if times will be overwritten, so call bulk_create_or_update with force option. If more than one
      # row was submitted, call bulk_create_or_update without force option.

      if effort_data.valid? && (effort_data.clean? || force_option?) && create_or_update_times(effort_data)
        EffortOffsetTimeAdjuster.adjust(effort: effort_data.effort)
        NotifyFollowersJob.perform_later(participant_id: effort_data.participant_id,
                                         split_time_ids: saved_split_times.map(&:id),
                                         multi_lap: event.multiple_laps?)
      end
      EffortDataStatusSetter.set_data_status(effort: effort_data.effort, times_container: times_container)
    end
  end

  def returned_rows
    {returned_rows: unsaved_rows}.camelize_keys
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
    row_success = true

    effort_data.proposed_split_times.each do |proposed_split_time|
      working_split_time = indexed_split_times[proposed_split_time.time_point] || proposed_split_time
      saved_split_time = create_or_update_split_time(proposed_split_time, working_split_time)
      if saved_split_time
        EffortStopper.stop(effort: effort, stopped_split_time: saved_split_time) if saved_split_time.stopped_here
        saved_split_times << saved_split_time
      else
        unsaved_rows << effort_data.response_row
        row_success = false
      end
    end
    row_success
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