module EventsHelper

  def make_event_split_id_array(event_id, splits)
    event_split_id_array = []
    splits.each do |split|
      @event_split = EventSplit.find_by(event_id: event_id, split_id: split.id)
      event_split_id_array << @event_split.id
    end
    event_split_id_array
  end

  def suggested_match(effort)
    Participant.where_name_matches(effort.first_name, effort.last_name).first
  end

  def suggested_match_description(effort)
    return nil unless suggested_match(effort)
    participant = suggested_match(effort)
    "#{participant.full_name} - #{participant.bio} - #{state_and_country_of(participant)}"
  end

  def effort_description(effort)
    "#{effort.full_name} - #{effort.bio} - #{state_and_country_of(effort)}"
  end

end
