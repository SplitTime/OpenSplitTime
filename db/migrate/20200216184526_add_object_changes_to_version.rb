class AddObjectChangesToVersion < ActiveRecord::Migration[5.2]
  def change
    add_column :versions, :object_changes, :json
  end
end
