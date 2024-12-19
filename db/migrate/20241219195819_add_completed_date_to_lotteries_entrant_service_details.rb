class AddCompletedDateToLotteriesEntrantServiceDetails < ActiveRecord::Migration[7.0]
  def change
    add_column :lotteries_entrant_service_details, :completed_date, :date
  end
end
