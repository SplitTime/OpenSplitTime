class CreateConnections < ActiveRecord::Migration[7.0]
  def change
    create_table :connections do |t|
      t.string :service_identifier, null: false
      t.string :source_type, null: false
      t.string :source_id, null: false
      t.references :destination, polymorphic: true, null: false, index: true

      t.timestamps

      t.index [:service_identifier, :source_type, :source_id, :destination_type, :destination_id],
              unique: true,
              name: "index_connections_on_service_source_and_destination"
    end
  end
end
