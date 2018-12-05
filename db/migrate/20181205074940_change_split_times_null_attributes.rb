class ChangeSplitTimesNullAttributes < ActiveRecord::Migration[5.1]
  def change
    change_column_null :split_times, :lap, false
    change_column_null :split_times, :sub_split_bitkey, false
    change_column_null :split_times, :absolute_time, false
  end
end
