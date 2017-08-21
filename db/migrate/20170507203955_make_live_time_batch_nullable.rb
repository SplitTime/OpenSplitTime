class MakeLiveTimeBatchNullable < ActiveRecord::Migration
  def up
    change_column_null :live_times, :batch, true
  end

  def down
    change_column_null :live_times, :batch, false
  end
end
