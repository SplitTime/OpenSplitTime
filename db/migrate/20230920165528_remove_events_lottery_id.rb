class RemoveEventsLotteryId < ActiveRecord::Migration[7.0]
  def change
    remove_reference :events, :lottery, index: true, foreign_key: true
  end
end
