module EventsHelper

  def make_event_split_id_array(event_id, splits)
    event_split_id_array = []
    splits.each do |split|
      @event_split = AidStation.find_by(event_id: event_id, split_id: split.id)
      event_split_id_array << @event_split.id
    end
    event_split_id_array
  end

  def make_suggested_match_id_hash(efforts)
    id_hash = {}
    efforts.each do |effort|
      id_hash[effort.id] = effort.suggested_match.id if effort.suggested_match
    end
    id_hash
  end

  def suggested_match_count(efforts)
    make_suggested_match_id_hash(efforts).count
  end

  def data_status(status_int)
    Effort.data_statuses.key(status_int)
  end

end
