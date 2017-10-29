class AddUniqueIndexToLiveTimes < ActiveRecord::Migration[5.1]
  def change
    add_index :live_times, [:absolute_time, :event_id, :split_id, :bitkey, :bib_number, :source, :with_pacer, :stopped_here, :remarks], unique: true, name: 'live_time_unique_absolute_times_index'
    add_index :live_times, [:entered_time, :event_id, :split_id, :bitkey, :bib_number, :source, :with_pacer, :stopped_here, :remarks], unique: true, name: 'live_time_unique_entered_times_index'
  end
end
