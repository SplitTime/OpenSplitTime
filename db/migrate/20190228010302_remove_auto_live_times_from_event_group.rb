class RemoveAutoLiveTimesFromEventGroup < ActiveRecord::Migration[5.2]
  def change
    remove_column :event_groups, :auto_live_times, :boolean
  end
end
