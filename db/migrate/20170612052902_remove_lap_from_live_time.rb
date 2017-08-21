class RemoveLapFromLiveTime < ActiveRecord::Migration
  def change
    remove_column :live_times, :lap, :integer
  end
end
