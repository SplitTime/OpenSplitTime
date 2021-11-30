class LotterySimulations < ActiveRecord::Migration[6.1]
  def change
    create_table :lottery_simulations do |t|
      t.references :lottery_simulation_run, null: false, foreign_key: true
      t.integer :ticket_ids, array: true, default: []
      t.jsonb :context

      t.timestamps
    end
  end
end
