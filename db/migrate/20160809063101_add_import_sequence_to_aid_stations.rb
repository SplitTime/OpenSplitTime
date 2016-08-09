class AddImportSequenceToAidStations < ActiveRecord::Migration
  def change
    add_column :aid_stations, :import_sequence_id, :integer, default: 0
  end
end
