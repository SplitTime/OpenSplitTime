class AddHomeTimeZoneToEventGroups < ActiveRecord::Migration[5.2]
  def up
    add_column :event_groups, :home_time_zone, :string

    execute <<-SQL.squish
        UPDATE event_groups
           SET home_time_zone = (SELECT events.home_time_zone
                                   FROM events
                                  WHERE events.event_group_id = event_groups.id
                                  LIMIT 1)
    SQL
  end

  def down
    remove_column :event_groups, :home_time_zone, :string
  end
end
