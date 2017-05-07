class RemoveRecordedAtFromLiveTimes < ActiveRecord::Migration
  def change
    remove_column :live_times, :recorded_at, :datetime
  end
end
