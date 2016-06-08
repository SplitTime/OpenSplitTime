{
        eventId: @event.id,
        eventName: @event.name,
        splits: @event.ordered_splits.map do |split|
            {
                    id: split.id,
                    base_name: split.base_name,
                    distance_from_start: "#{d(split.distance_from_start)} #{pdu('short')}",
                    sub_split_in: split.bitkey_hash_in.present?,
                    sub_split_out: split.bitkey_hash_out.present?
            }
        end
}.to_json