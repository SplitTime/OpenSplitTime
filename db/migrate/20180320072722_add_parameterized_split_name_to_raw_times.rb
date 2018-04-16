class AddParameterizedSplitNameToRawTimes < ActiveRecord::Migration[5.1]
  def up
    add_column :raw_times, :parameterized_split_name, :string
    RawTime.find_each(&:save)
    change_column_null :raw_times, :parameterized_split_name, false
  end

  def down
    remove_column :raw_times, :parameterized_split_name, :string
  end
end
