class CreateGatingLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :gating_locations do |t|
      t.references :event_group, null: false, foreign_key: true, type: :integer
      t.string :name, null: false
      t.timestamps
    end
    add_index :gating_locations, [:event_group_id, :name], unique: true

    create_table :gating_location_events do |t|
      t.references :gating_location, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true, type: :integer
      t.references :gating_aid_station, null: false, type: :integer, foreign_key: { to_table: :aid_stations }
      t.references :target_aid_station, null: false, type: :integer, foreign_key: { to_table: :aid_stations }
      t.timestamps
    end
    add_index :gating_location_events, [:gating_location_id, :event_id], unique: true
  end
end
