{
        eventId: @event.id,
        eventName: @event.name,
        multiLap: @event.multiple_laps?,
        maximumLaps: @event.maximum_laps,
        splits: @event.ordered_splits.map do |split|
            {
                    id: split.id,
                    base_name: split.base_name,
                    distance_from_start: "#{d(split.distance_from_start)} #{pdu('short')}",
                    sub_split_in: split.sub_split_in.present?,
                    sub_split_out: split.sub_split_out.present?
            }
        end
}.to_json