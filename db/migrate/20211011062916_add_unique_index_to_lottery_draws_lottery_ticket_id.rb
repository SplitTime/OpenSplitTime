class AddUniqueIndexToLotteryDrawsLotteryTicketId < ActiveRecord::Migration[6.1]
  def change
    remove_index :lottery_draws, :lottery_ticket_id
    add_index :lottery_draws, :lottery_ticket_id, unique: true
  end
end
