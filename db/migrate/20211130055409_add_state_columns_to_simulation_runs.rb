class AddStateColumnsToSimulationRuns < ActiveRecord::Migration[6.1]
  def change
    add_column :lottery_simulation_runs, :requested_count, :integer
    add_column :lottery_simulation_runs, :status, :integer
    add_column :lottery_simulation_runs, :error_message, :string
    add_column :lottery_simulation_runs, :success_count, :integer
    add_column :lottery_simulation_runs, :failure_count, :integer
    add_column :lottery_simulation_runs, :started_at, :datetime
    add_column :lottery_simulation_runs, :elapsed_time, :integer
  end
end
