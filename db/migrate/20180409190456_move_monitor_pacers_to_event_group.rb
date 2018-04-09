class MoveMonitorPacersToEventGroup < ActiveRecord::Migration[5.1]
  def up
    add_column :event_groups, :monitor_pacers, :boolean, default: false
    EventGroup.find_each do |event_group|
      event_group.update(monitor_pacers: true) if event_group.events.any?(&:monitor_pacers)
    end
    remove_column :events, :monitor_pacers, :boolean, default: false
  end

  def down
    add_column :events, :monitor_pacers, :boolean, default: false
    Event.find_each do |event|
      event.update(monitor_pacers: true) if event.event_group.monitor_pacers
    end
    remove_column :event_groups, :monitor_pacers, :boolean, default: false
  end
end
