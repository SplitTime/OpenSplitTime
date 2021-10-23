class IndexLotteryTicketReferenceNumbers < ActiveRecord::Migration[6.1]
  def change
    add_index :lottery_tickets, :reference_number
  end
end
