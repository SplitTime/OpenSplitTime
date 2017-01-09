class AddLapToSplitTimes < ActiveRecord::Migration
  def change
    add_column :split_times, :lap, :integer, default: 1
  end
end