class DataStatusService

  def self.set_data_status(*efforts)
    update_effort_hash = {}
    update_split_time_hash = {}
    event = efforts.first.event
    cache = SegmentCalculationsCache.new(event)

    efforts.each do |effort|
      status_array = []
      latest_valid_split_time = effort.start_split_time

      effort.ordered_split_times.each do |split_time|
        if split_time.confirmed?
          latest_valid_split_time = split_time
          next
        end
        segment = Segment.new(latest_valid_split_time.split, split_time.split)
        segment_time = segment.end_split.start? ?
            split_time.time_from_start :
            split_time.time_from_start - latest_valid_split_time.time_from_start
        status = cache.get_data_status(segment, segment_time)
        status_array << status
        latest_valid_split_time = split_time if status == :good
        update_split_time_hash[split_time.id] = status if status != split_time.data_status.try(:to_sym)
      end

      effort_status = DataStatus.get_lowest_data_status(status_array)
      update_effort_hash[effort.id] = effort_status if effort_status != effort.data_status.try(:to_sym)
    end

    BulkUpdateService.bulk_update_split_time_status(update_split_time_hash)
    BulkUpdateService.bulk_update_effort_status(update_effort_hash)
  end

end