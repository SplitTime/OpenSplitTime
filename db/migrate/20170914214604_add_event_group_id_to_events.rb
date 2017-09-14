class AddEventGroupIdToEvents < ActiveRecord::Migration[5.0]
  def self.up
    add_reference :events, :event_group, foreign_key: true
    grouped_events = Event.all.group_by do |event|
      [event.organization_id, event.start_time.to_date]
    end
    grouped_events.each do |_, events|
      name = events.one? ? events.first.name : events.first.name.longest_common_phrase(events.second.name)
      event_group = EventGroup.create!(name: name)
      events.each { |event| event.update!(event_group: event_group) }
    end
  end

  def self.down
    remove_reference :events, :event_group
  end
end
