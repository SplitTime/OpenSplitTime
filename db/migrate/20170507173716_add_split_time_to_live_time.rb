class AddSplitTimeToLiveTime < ActiveRecord::Migration
  def change
    add_reference :live_times, :split_time, index: true, foreign_key: true, null: true
  end
end
