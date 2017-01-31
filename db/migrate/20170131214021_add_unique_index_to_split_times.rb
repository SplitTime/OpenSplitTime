class AddUniqueIndexToSplitTimes < ActiveRecord::Migration
  def change
    add_index :split_times,
              [:effort_id, :lap, :split_id, :sub_split_bitkey],
              unique: true,
              name: 'index_split_times_on_effort_id_and_time_point'
  end
end