class RemoveSpreadCacheEntries < ActiveRecord::Migration[8.1]
  def up
    execute(<<~SQL.squish)
      DELETE FROM solid_cache_entries
      WHERE encode(key, 'escape') LIKE 'views/events/spread:%'
    SQL

    execute(<<~SQL.squish)
      DELETE FROM solid_cache_dashboard_events
      WHERE key_string LIKE 'views/events/spread:%'
    SQL
  end

  def down
    # Irreversible: cache fragments and dashboard events are ephemeral
    # observational artifacts that reconstruct themselves as traffic
    # hits the spread endpoint. There is nothing meaningful to restore.
  end
end
