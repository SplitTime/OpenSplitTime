class CreateLotteryDivisionTicketStats < ActiveRecord::Migration[7.0]
  def change
    create_view :lottery_division_ticket_stats
  end
end
