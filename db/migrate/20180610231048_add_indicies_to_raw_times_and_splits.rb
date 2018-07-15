class AddIndiciesToRawTimesAndSplits < ActiveRecord::Migration[5.1]
  def change
    add_index :raw_times, [:absolute_time, :event_group_id, :parameterized_split_name, :bitkey, :bib_number, :source, :with_pacer, :stopped_here, :remarks], unique: true, name: 'raw_time_unique_absolute_times_index'
    add_index :raw_times, [:entered_time, :event_group_id, :parameterized_split_name, :bitkey, :bib_number, :source, :with_pacer, :stopped_here, :remarks], unique: true, name: 'raw_time_unique_entered_times_index'
    add_index :raw_times, :parameterized_split_name

    add_index :splits, :parameterized_base_name
  end
end
