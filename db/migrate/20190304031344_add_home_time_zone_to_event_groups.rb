class AddHomeTimeZoneToEventGroups < ActiveRecord::Migration[5.2]
  def up
    add_column :event_groups, :home_time_zone, :string

    EventGroup.all.includes(:events).each do |event_group|
      event_group.update!(home_time_zone: event_group.events.first.home_time_zone)
    end
  end

  def down
    Event.all.includes(:event_group).each do |event|
      event.update(home_time_zone: event.event_group.home_time_zone)
    end

    remove_column :event_groups, :home_time_zone, :string
  end
end
