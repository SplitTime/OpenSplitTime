class RequireMaximumumsInLotteryDivisions < ActiveRecord::Migration[6.1]
  def change
    change_column_null :lottery_divisions, :maximum_entries, false
  end
end
