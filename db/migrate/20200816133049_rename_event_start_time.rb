class RenameEventStartTime < ActiveRecord::Migration[5.2]
  def change
    rename_column :events, :start_time, :scheduled_start_time
  end
end
