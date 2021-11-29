class RemoveTimeIndiciesFromRawTimes < ActiveRecord::Migration[5.1]
  def change
    remove_index :raw_times, column: [:absolute_time, :event_group_id, :parameterized_split_name, :bitkey, :bib_number, :source, :with_pacer, :stopped_here, :remarks], unique: true, name: 'raw_time_unique_absolute_times_index'
    remove_index :raw_times, column: [:entered_time, :event_group_id, :parameterized_split_name, :bitkey, :bib_number, :source, :with_pacer, :stopped_here, :remarks], unique: true, name: 'raw_time_unique_entered_times_index'
  end
end
