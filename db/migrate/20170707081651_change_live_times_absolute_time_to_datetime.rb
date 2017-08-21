class ChangeLiveTimesAbsoluteTimeToDatetime < ActiveRecord::Migration
  def self.up
    change_column :live_times, :absolute_time, 'timestamp USING CAST(absolute_time AS timestamp)', null: true
  end

  def self.down
    change_column :live_times, :absolute_time, :string, null: false
  end
end
