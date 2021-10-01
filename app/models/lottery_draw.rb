class LotteryDraw < ApplicationRecord
  belongs_to :lottery
  belongs_to :ticket, class_name: "LotteryTicket", foreign_key: :lottery_ticket_id
end
