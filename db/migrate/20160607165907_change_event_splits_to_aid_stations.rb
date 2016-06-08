class ChangeEventSplitsToAidStations < ActiveRecord::Migration
  def change
    rename_table :event_splits, :aid_stations
    add_column :aid_stations, :open_time, :datetime
    add_column :aid_stations, :close_time, :datetime
    add_column :aid_stations, :status, :integer
    add_column :aid_stations, :captain_name, :string
    add_column :aid_stations, :comms_chief_name, :string
    add_column :aid_stations, :comms_frequencies, :string
    add_column :aid_stations, :current_issues, :string
  end
end
