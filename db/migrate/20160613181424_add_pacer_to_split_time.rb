class AddPacerToSplitTime < ActiveRecord::Migration
  def change
    add_column :split_times, :pacer, :boolean
  end
end
