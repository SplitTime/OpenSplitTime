class AddRemarksToSplitTimes < ActiveRecord::Migration
  def change
    add_column :split_times, :remarks, :string
  end
end
