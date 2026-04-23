class RemoveRackAttackCacheEntries < ActiveRecord::Migration[8.1]
  def up
    execute(<<~SQL.squish)
      DELETE FROM solid_cache_entries
      WHERE encode(key, 'escape') LIKE 'rack::attack:%'
    SQL
  end

  def down
    # Irreversible: rack-attack is removed, so there is no writer to
    # repopulate these counters. The entries are also ephemeral by
    # design (60s TTL) and would have expired on their own.
  end
end
