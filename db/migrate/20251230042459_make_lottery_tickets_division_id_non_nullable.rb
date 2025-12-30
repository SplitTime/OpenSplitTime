class MakeLotteryTicketsDivisionIdNonNullable < ActiveRecord::Migration[7.2]
  def change
    change_column_null :lottery_tickets, :lottery_division_id, false
  end
end
