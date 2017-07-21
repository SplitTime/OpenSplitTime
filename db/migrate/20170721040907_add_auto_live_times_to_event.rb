class AddAutoLiveTimesToEvent < ActiveRecord::Migration
  def change
    add_column :events, :auto_live_times, :boolean, default: false
  end
end
