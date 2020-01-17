class RemoveNameFromEvents < ActiveRecord::Migration[5.2]
  def change
    rename_column :events, :name, :historical_name
    change_column_null :events, :historical_name, true
    add_index :events, [:event_group_id, :short_name], unique: true
  end
end
