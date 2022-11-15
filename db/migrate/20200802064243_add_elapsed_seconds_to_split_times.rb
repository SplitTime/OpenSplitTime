class AddElapsedSecondsToSplitTimes < ActiveRecord::Migration[5.2]
  def change
    add_column :split_times, :elapsed_seconds, :float
  end
end
