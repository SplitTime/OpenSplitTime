class AddServiceCompletedDateToLotteryEntrants < ActiveRecord::Migration[7.0]
  def change
    add_column :lottery_entrants, :service_completed_date, :date
  end
end
