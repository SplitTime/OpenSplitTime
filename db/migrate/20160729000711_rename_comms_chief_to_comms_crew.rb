class RenameCommsChiefToCommsCrew < ActiveRecord::Migration
  def change
    rename_column :aid_stations, :comms_chief_name, :comms_crew_names
  end
end
