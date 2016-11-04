class DataStatusService

  def self.set_data_status(*efforts)
    efforts = efforts.flatten
    return 'This event has no efforts whose times can be verified.' if efforts.empty?
    update_effort_hash = {}
    update_split_time_hash = {}
    event = efforts.first.event
    event_segment_calcs = EventSegmentCalcs.new(event)
    ordered_splits = event.ordered_splits
    splits = ordered_splits.index_by(&:id)
    split_time_groups = SplitTime.select(:id, :sub_split_bitkey, :split_id, :time_from_start, :data_status)
                      .where(effort_id: efforts.map(&:id))
                      .ordered
                      .group_by(&:effort_id)
    return "This event's efforts have no split times to be verified." if split_time_groups.empty?

    split_time_groups.each do |effort_id, split_times|
      effort = efforts.find { |effort| effort.id == effort_id }
      status_array = []
      latest_valid_split_time = split_times.first
      ordered_split_ids = ordered_splits.map(&:id)
      dropped_index = ordered_split_ids.index(effort.dropped_split_id)

      split_times.each do |split_time|
        if split_time.confirmed?
          latest_valid_split_time = split_time
          next
        end
        if dropped_index && (ordered_split_ids.index(split_time.split_id) > dropped_index)
          status = 'bad'
        else
          segment = Segment.new(latest_valid_split_time.bitkey_hash,
                                split_time.bitkey_hash,
                                splits[latest_valid_split_time.split_id],
                                splits[split_time.split_id])
          segment_time = segment.end_split.start? ?
              split_time.time_from_start :
              split_time.time_from_start - latest_valid_split_time.time_from_start
          status = event_segment_calcs.get_data_status(segment, segment_time)
        end
        status_array << status
        latest_valid_split_time = split_time if status == 'good'
        update_split_time_hash[split_time.id] = status if status != split_time.data_status
      end

      effort_status = DataStatus.worst(status_array)
      update_effort_hash[effort_id] = effort_status if effort_status != effort.data_status
    end

    BulkUpdateService.bulk_update_split_time_status(update_split_time_hash)
    BulkUpdateService.bulk_update_effort_status(update_effort_hash)
    return 'Bad and questionable times have been flagged.'
  end

  def self.live_entry_data_status(effort, ordered_splits, ordered_split_times, event_segment_calcs)
    indexed_splits = ordered_splits.index_by(&:id)
    ordered_split_ids = ordered_splits.map(&:id)
    dropped_index = ordered_split_ids.index(effort.dropped_split_id)
    status_hash = {}
    latest_valid_split_time = ordered_split_times.first

    ordered_split_times.each do |split_time|
      subject_bitkey_hash = split_time.bitkey_hash
      if split_time.confirmed?
        status = 'confirmed'
        latest_valid_split_time = split_time
      else
        if dropped_index && (ordered_split_ids.index(split_time.split_id) > dropped_index)
          status = 'bad'
        else
          segment = Segment.new(latest_valid_split_time.bitkey_hash,
                                split_time.bitkey_hash,
                                indexed_splits[latest_valid_split_time.split_id],
                                indexed_splits[split_time.split_id])
          segment_time = split_time.time_from_start - latest_valid_split_time.time_from_start
          status = event_segment_calcs.get_data_status(segment, segment_time)
          latest_valid_split_time = split_time if status == 'good'
        end
      end
      status_hash[subject_bitkey_hash] = status
    end
    status_hash
  end

end