class AddStoppedHereToSplitTimes < ActiveRecord::Migration
  def change
    add_column :split_times, :stopped_here, :boolean, default: false
  end
end