class MovePartnersToEventGroup < ActiveRecord::Migration[5.1]
  def up
    add_column :partners, :event_group_id, :bigint

    Partner.find_each do |partner|
      event = Event.find(partner.event_id)
      partner.update(event_group_id: event.event_group_id)
    end

    change_column_null :partners, :event_group_id, false
    add_index :partners, :event_group_id

    remove_column :partners, :event_id
  end

  def down
    add_column :partners, :event_id, :bigint

    Partner.find_each do |partner|
      event_group = EventGroup.find(partner.event_group_id)
      partner.update(event_id: event_group.events.first.id)
    end

    change_column_null :partners, :event_id, false
    add_index :partners, :event_id

    remove_column :partners, :event_group_id
  end
end
