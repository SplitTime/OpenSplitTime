class UpdateLotteriesCalculationsHilo2025sToVersion2 < ActiveRecord::Migration[7.1]
  def change
    update_view :lotteries_calculations_hilo_2025s, version: 2, revert_to_version: 1
  end
end
