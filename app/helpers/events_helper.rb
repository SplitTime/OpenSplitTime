module EventsHelper

  def make_event_split_id_array(event_id, splits)
    event_split_id_array = []
    splits.each do |split|
      @event_split = EventSplit.find_by(event_id: event_id, split_id: split.id)
      event_split_id_array << @event_split.id
    end
    event_split_id_array
  end

end
