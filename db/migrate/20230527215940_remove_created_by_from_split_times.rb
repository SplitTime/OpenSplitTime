class RemoveCreatedByFromSplitTimes < ActiveRecord::Migration[7.0]
  def change
    remove_column :split_times, :created_by, :integer
  end
end
