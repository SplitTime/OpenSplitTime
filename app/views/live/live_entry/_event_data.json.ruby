{
        eventId: @event.id,
        eventName: @event.name,
        splits: @event.ordered_splits.map do |split|
            {
                    id: split.id,
                    base_name: split.base_name,
                    distance_from_start: "#{d(split.distance_from_start)} #{pdu('short')}",
            }
        end
}.to_json