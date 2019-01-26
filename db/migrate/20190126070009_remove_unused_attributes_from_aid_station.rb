class RemoveUnusedAttributesFromAidStation < ActiveRecord::Migration[5.1]
  def change
    remove_column :aid_stations, :open_time, :datetime
    remove_column :aid_stations, :close_time, :datetime
    remove_column :aid_stations, :status, :integer
    remove_column :aid_stations, :captain_name, :string
    remove_column :aid_stations, :comms_crew_names, :string
    remove_column :aid_stations, :comms_frequencies, :string
    remove_column :aid_stations, :current_issues, :string
  end
end
