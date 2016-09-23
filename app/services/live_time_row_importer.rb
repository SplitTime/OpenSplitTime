class LiveTimeRowImporter

  def initialize(event, time_rows)
    @event = event
    @time_rows = time_rows
    @unsaved_rows = []
    import_time_rows
  end

  def returned_rows
    unsaved_rows
  end

  private

  attr_reader :event, :time_rows
  attr_accessor :unsaved_rows

  # If just one row was submitted, assume the user has noticed if data status is bad or questionable,
  # or if times will be overwritten, so call bulk_create_or_update with force option. If more than one
  # row was submitted, call bulk_create_or_update without force option.

  def import_time_rows
    calcs = EventSegmentCalcs.new(event)
    ordered_split_array = event.ordered_splits.to_a
    force_option = time_rows.count == 1 ? 'force' : nil
    time_rows.each do |time_row|

      # time_row[0] is an id number used by the live entry javascript but not needed by the importer,
      # so just use time_row[1], which contains the needed data.

      effort_data_object = LiveEffortData.new(event, time_row[1], calcs, ordered_split_array)
      if effort_data_object.success? && (effort_data_object.clean? || (force_option == 'force'))
        if create_or_update_times(effort_data_object)
          effort = effort_data_object.effort
          dropped_split_id = effort_data_object.dropped_here ? effort_data_object.split_id : nil
          if dropped_split_id && (effort.dropped_split_id != dropped_split_id)
            effort.update(dropped_split_id: dropped_split_id)
            DataStatusService.set_data_status(effort)
          end
          if !dropped_split_id && (effort.dropped_split_id == effort_data_object.split_id)
            effort.update(dropped_split_id: nil)
            DataStatusService.set_data_status(effort)
          end
        else
          unsaved_rows << effort_data_object.response_row
        end
      else
        unsaved_rows << effort_data_object.response_row
      end
    end
  end

  # The effort_data_object may or may not include an 'in' time or an 'out' time.
  # Returns true if available times (in or out or both) are created/updated.
  # Returns false if either in or out create/update is attempted but rejected

  def create_or_update_times(effort_data_object)

    # Pull any existing split_times from the database so we have the latest info available

    existing_split_times = SplitTime.where(split_id: effort_data_object.split_id,
                                           effort_id: effort_data_object.effort_id).to_a
    in_time_saved = out_time_saved = nil
    split_time_ids = []
    if effort_data_object.split_time_in.present?
      split_time_in = existing_split_times.find { |st| st.sub_split_bitkey == SubSplit::IN_BITKEY }
      in_time_saved = create_or_update_split_time(effort_data_object.split_time_in, split_time_in)
      split_time_ids << in_time_saved if in_time_saved
    end

    if (effort_data_object.split_time_out.present?) && (effort_data_object.sub_split_bitkey_out?)
      split_time_out = existing_split_times.find { |st| st.sub_split_bitkey == SubSplit::OUT_BITKEY }
      out_time_saved = create_or_update_split_time(effort_data_object.split_time_out, split_time_out)
      split_time_ids << out_time_saved if out_time_saved
    end
    FollowerMailerService.send_live_effort_mail(effort_data_object.participant_id, split_time_ids)
    # FollowerMailerJob.perform_later(effort_data_object.participant_id, split_time_ids)
    !((in_time_saved == false) || (out_time_saved == false)) # This formulation is needed for nil handling.
  end

  # If existing_split_time is present, update it using proposed_split_time data.
  # If not, create proposed_split_time.

  def create_or_update_split_time(proposed_split_time, existing_split_time)
    if existing_split_time.present?
      update = existing_split_time.update(time_from_start: proposed_split_time.time_from_start,
                                          data_status: proposed_split_time.data_status,
                                          pacer: proposed_split_time.pacer,
                                          remarks: proposed_split_time.remarks)
      update ? existing_split_time.id : false
    else
      create = proposed_split_time.save
      create ? proposed_split_time.id : false
    end
  end

end