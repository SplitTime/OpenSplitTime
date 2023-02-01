class RenameSyncRelationsToSyncableRelations < ActiveRecord::Migration[7.0]
  def change
    rename_table :sync_relations, :syncable_relations
  end
end
