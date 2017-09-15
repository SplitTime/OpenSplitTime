class AddSlugToEventGroups < ActiveRecord::Migration[5.0]
  def self.up
    add_column :event_groups, :slug, :string
    add_index :event_groups, :slug, unique: true

    grouped_events = Event.all.group_by { |event| [event.organization_id, event.start_time.to_date] }

    grouped_events.each do |_, events|
      group_name = String.longest_common_phrase(events.map(&:name)).titlecase
      event_group = EventGroup.create!(name: group_name)
      events.each { |event| event.update!(event_group: event_group) }
    end

    change_column_null :event_groups, :slug, false
  end

  def self.down
    remove_column :event_groups, :slug
  end
end
