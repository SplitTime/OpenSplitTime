class AddRankingColumnsToEfforts < ActiveRecord::Migration[7.0]
  def change
    add_column :efforts, :started, :boolean
    add_column :efforts, :beyond_start, :boolean
    add_column :efforts, :dropped, :boolean
    add_column :efforts, :stopped, :boolean
    add_column :efforts, :finished, :boolean
    add_column :efforts, :laps_started, :integer
    add_column :efforts, :laps_finished, :integer
    add_column :efforts, :overall_rank, :integer
    add_column :efforts, :gender_rank, :integer
  end
end
