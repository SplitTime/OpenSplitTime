class MakeLiveTimesBitkeyNotNullable < ActiveRecord::Migration
  def change
    change_column_null :live_times, :bitkey, false
  end
end
