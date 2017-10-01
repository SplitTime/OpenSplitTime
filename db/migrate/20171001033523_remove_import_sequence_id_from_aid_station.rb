class RemoveImportSequenceIdFromAidStation < ActiveRecord::Migration[5.0]
  def change
    remove_column :aid_stations, :import_sequence_id, :integer
  end
end
