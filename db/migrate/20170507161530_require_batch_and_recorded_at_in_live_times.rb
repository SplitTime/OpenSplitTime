class RequireBatchAndRecordedAtInLiveTimes < ActiveRecord::Migration
  def up
    change_column_null :live_times, :batch, false
    change_column_null :live_times, :recorded_at, false
  end

  def down
    change_column_null :live_times, :batch, true
    change_column_null :live_times, :recorded_at, true
  end
end
