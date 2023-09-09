# frozen_string_literal: true

class MigrateSyncableRelationsToConnections < ActiveRecord::Migration[7.0]
  def up
    SyncableRelation.find_each do |syncable_relation|
      Connection.find_or_create_by!(
        service_identifier: syncable_relation.source_name,
        source_type: syncable_relation.source_type,
        source_id: syncable_relation.source_id,
        destination_type: syncable_relation.destination_type,
        destination_id: syncable_relation.destination_id
      )
    end
  end

  def down
  end
end
