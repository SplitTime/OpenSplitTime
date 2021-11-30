class AddLotterySimulationRuns < ActiveRecord::Migration[6.1]
  def change
    create_table :lottery_simulation_runs do |t|
      t.references :lottery, null: false, foreign_key: true
      t.string :name
      t.jsonb :context

      t.timestamps
    end
  end
end
