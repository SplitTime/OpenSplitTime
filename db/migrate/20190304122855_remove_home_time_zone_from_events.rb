class RemoveHomeTimeZoneFromEvents < ActiveRecord::Migration[5.2]
  def up
    remove_column :events, :home_time_zone, :string
  end

  def down
    add_column :events, :home_time_zone, :string

    execute <<-SQL.squish
        UPDATE events
           SET home_time_zone = (SELECT event_groups.home_time_zone
                                   FROM event_groups
                                  WHERE events.event_group_id = event_groups.id)
    SQL
  end
end
