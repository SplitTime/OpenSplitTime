class DataStatusService

  def self.set_data_status(*efforts)
    efforts = efforts.flatten
    update_effort_hash = {}
    update_split_time_hash = {}
    event = efforts.first.event
    event_segment_calcs = EventSegmentCalcs.new(event)
    splits = event.ordered_splits.index_by(&:id)
    split_times = SplitTime.select(:id, :sub_split_bitkey, :split_id, :time_from_start, :data_status).where(effort_id: efforts.map(&:id)).ordered.group_by(&:effort_id)

    efforts.each do |effort|
      status_array = []
      latest_valid_split_time = split_times[effort.id].first

      split_times[effort.id].each do |split_time|
        if split_time.confirmed?
          latest_valid_split_time = split_time
          next
        end
        segment = Segment.new(latest_valid_split_time.bitkey_hash,
                              split_time.bitkey_hash,
                              splits[latest_valid_split_time.split_id],
                              splits[split_time.split_id])
        segment_time = segment.end_split.start? ?
            split_time.time_from_start :
            split_time.time_from_start - latest_valid_split_time.time_from_start
        status = event_segment_calcs.get_data_status(segment, segment_time)
        status_array << status
        latest_valid_split_time = split_time if status == 'good'
        update_split_time_hash[split_time.id] = status if status != split_time.data_status
      end

      effort_status = DataStatus.worst(status_array)
      update_effort_hash[effort.id] = effort_status if effort_status != effort.data_status
    end

    BulkUpdateService.bulk_update_split_time_status(update_split_time_hash)
    BulkUpdateService.bulk_update_effort_status(update_effort_hash)
  end

end