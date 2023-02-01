class CreateSyncRelations < ActiveRecord::Migration[7.0]
  def change
    create_table :sync_relations do |t|
      t.string :source_name
      t.string :source_type
      t.string :source_id
      t.string :destination_name
      t.string :destination_type
      t.string :destination_id

      t.timestamps
    end
  end
end
