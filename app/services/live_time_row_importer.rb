class LiveTimeRowImporter

  attr_accessor :effort_data_objects

  def initialize(event, time_rows)
    @event = event
    @time_rows = time_rows
    @unsaved_rows = []
    create_effort_data_objects
    handle_effort_data_objects
  end

  def returned_rows
    unsaved_rows
  end

  private

  attr_reader :event, :time_rows
  attr_accessor :unsaved_rows

  def create_effort_data_objects
    calcs = EventSegmentCalcs.new(event)
    ordered_split_array = event.ordered_splits.to_a
    self.effort_data_objects = []
    time_rows.each do |time_row|
      effort_data_object = LiveEffortData.new(event, time_row[1], calcs, ordered_split_array)
      effort_data_objects << effort_data_object
    end
  end

  # If just one row was submitted, assume the user has noticed if data status is bad or questionable,
  # or if times will be overwritten, so call bulk_create_or_update with force option. If more than one
  # row was submitted, call bulk_create_or_update without force option.

  def handle_effort_data_objects
    force_option = effort_data_objects.count == 1 ? 'force' : nil
    bulk_create_or_update_times(force_option)
  end

  # Submit clean effort_data_objects for creation or updating,
  # and insert non-clean effort_data_objects into unsaved array
  # If option == 'force' then ignore 'clean?' status

  def bulk_create_or_update_times(option = nil)
    effort_data_objects.each do |effort_data_object|
      created_or_updated = nil
      if effort_data_object.clean? || (option == 'force')
        created_or_updated = create_or_update_times(effort_data_object)
      else
        unsaved_rows << effort_data_object.response_row
      end
      unsaved_rows << effort_data_object.response_row unless created_or_updated
    end
  end

  # The effort_data_object may or may not include an 'in' time or an 'out' time.
  # Returns true if available times (in or out or both) are created/updated.
  # Returns false if either in or out create/update is attempted but rejected

  def create_or_update_times(effort_data_object)

    # Pull any existing split_times from the database so we have the latest info available

    existing_split_times = SplitTime.where(split_id: effort_data_object.split_time_in.split_id,
                                           effort_id: effort_data_object.split_time_in.effort_id).to_a
    in_time_saved = out_time_saved = nil
    if effort_data_object.split_time_in.present?
      split_time_in = existing_split_times.find { |st| st.sub_split_bitkey == SubSplit::IN_BITKEY }
      in_time_saved = create_or_update_split_time(effort_data_object.split_time_in, split_time_in)
    end

    if effort_data_object.split_time_out.present?
      split_time_out = existing_split_times.find { |st| st.sub_split_bitkey == SubSplit::OUT_BITKEY }
      out_time_saved = create_or_update_split_time(effort_data_object.split_time_out, split_time_out)
    end
    !((in_time_saved == false) || (out_time_saved == false)) # This formulation is needed for nil handling.
  end

  # If existing_split_time is present, update it using proposed_split_time data.
  # If not, create proposed_split_time.

  def create_or_update_split_time(proposed_split_time, existing_split_time)
    if existing_split_time.present?
      existing_split_time.update(time_from_start: proposed_split_time.time_from_start,
                                 data_status: proposed_split_time.data_status)
    else
      proposed_split_time.save
    end
  end

end