class RenameLotterySimulationsContextToResults < ActiveRecord::Migration[6.1]
  def change
    rename_column :lottery_simulations, :context, :results
  end
end
