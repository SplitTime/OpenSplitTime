class AddOrganizationToEventGroups < ActiveRecord::Migration[5.0]
  def self.up

    grouped_events = Event.all.group_by { |event| [event.organization_id, event.start_time.to_date] }

    grouped_events.each do |_, events|
      first_event = events.first
      group_name = String.longest_common_phrase(events.map(&:name)).titlecase
      event_group = EventGroup.create!(name: group_name,
                                       organization_id: first_event.organization_id,
                                       available_live: first_event.available_live,
                                       auto_live_times: first_event.auto_live_times,
                                       concealed: first_event.concealed,
                                       created_by: first_event.created_by)
      events.each { |event| event.update!(event_group: event_group) }
    end
  end

  def self.down
    Event.update_all(event_group_id: nil)
    EventGroup.destroy_all
  end
end
