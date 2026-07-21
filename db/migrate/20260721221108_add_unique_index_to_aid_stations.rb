class AddUniqueIndexToAidStations < ActiveRecord::Migration[8.1]
  def change
    add_index :aid_stations, [:event_id, :split_id], unique: true

    # Redundant once the composite exists: (event_id, split_id) also serves event_id-prefix lookups.
    remove_index :aid_stations, :event_id

    change_column_null :aid_stations, :event_id, false
    change_column_null :aid_stations, :split_id, false
  end
end
