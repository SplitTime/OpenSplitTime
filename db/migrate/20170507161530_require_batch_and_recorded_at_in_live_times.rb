class RequireBatchAndRecordedAtInLiveTimes < ActiveRecord::Migration
  def change
    change_column :live_times, :batch, :string, null: false
    change_column :live_times, :recorded_at, :datetime, null: false
  end
end
