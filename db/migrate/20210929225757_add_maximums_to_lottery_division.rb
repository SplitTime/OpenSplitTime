class AddMaximumsToLotteryDivision < ActiveRecord::Migration[6.1]
  def change
    add_column :lottery_divisions, :maximum_entries, :integer
    add_column :lottery_divisions, :maximum_wait_list, :integer
  end
end
