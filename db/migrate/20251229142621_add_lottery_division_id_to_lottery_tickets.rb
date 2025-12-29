class AddLotteryDivisionIdToLotteryTickets < ActiveRecord::Migration[7.2]
  def change
    add_column :lottery_tickets, :lottery_division_id, :bigint

    add_index :lottery_tickets, :lottery_division_id
    add_index :lottery_tickets, [:lottery_division_id, :reference_number]
  end
end
