class LotteryDraw < ApplicationRecord
  belongs_to :lottery
  belongs_to :lottery_ticket
end
