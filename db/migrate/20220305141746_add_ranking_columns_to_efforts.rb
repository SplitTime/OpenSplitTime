class AddRankingColumnsToEfforts < ActiveRecord::Migration[7.0]
  def change
    add_column :efforts, :overall_performance, "bit(96)"
    add_column :efforts, :stopped_split_time_id, :integer
    add_column :efforts, :final_split_time_id, :integer
    add_column :efforts, :started, :boolean
    add_column :efforts, :beyond_start, :boolean
    add_column :efforts, :stopped, :boolean
    add_column :efforts, :dropped, :boolean
    add_column :efforts, :finished, :boolean
  end
end
