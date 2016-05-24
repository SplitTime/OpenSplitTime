class ModifyEventsStartTime < ActiveRecord::Migration
  def self.up
    rename_column :events, :first_start_time, :start_time
  end

  def self.down
    rename_column :events, :start_time, :first_start_time
  end
end
