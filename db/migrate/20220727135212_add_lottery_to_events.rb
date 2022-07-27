class AddLotteryToEvents < ActiveRecord::Migration[7.0]
  def change
    add_reference :events, :lottery, null: true, foreign_key: true
  end
end
