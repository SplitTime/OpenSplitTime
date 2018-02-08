class RemoveDroppedAttributesFromEffort < ActiveRecord::Migration[5.1]
  def change
    remove_column :efforts, :dropped_split_id, :string
    remove_column :efforts, :dropped_lap, :string
  end
end
