module EventsHelper

  def make_event_split_id_array(event_id, splits)
    event_split_id_array = []
    splits.each do |split|
      @event_split = EventSplit.find_by(event_id: event_id, split_id: split.id)
      event_split_id_array << @event_split.id
    end
    event_split_id_array
  end

  def make_exact_match_id_hash(efforts)
    id_hash = {}
    c = 0
    efforts.each do |effort|
      break if c >= 50
      @participant = effort.exact_matching_participant
      if @participant
        id_hash[effort.id] = @participant.id
        c += 1
      end
    end
    id_hash
  end

end
