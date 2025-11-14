# class DropLotteryTicketCalcHardrock2025s < ActiveRecord::Migration[7.0]
#   def change
#     drop_view :lottery_ticket_calc_hardrock_2025s
#   end
# end

class DropLotteryTicketCalcHardrock2025s < ActiveRecord::Migration[7.0]  # keep your version number
  def change
    # No-op for local development.
    # The `lottery_ticket_calc_hardrock_2025s` view does not exist
    # in this environment, so there is nothing to drop.
  end
end
