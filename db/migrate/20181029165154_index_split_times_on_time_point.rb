class IndexSplitTimesOnTimePoint < ActiveRecord::Migration[5.1]
  def change
    add_index :split_times, [:lap, :split_id, :sub_split_bitkey], name: :index_split_times_on_time_point
  end
end
