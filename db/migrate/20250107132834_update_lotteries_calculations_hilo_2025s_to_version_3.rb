class UpdateLotteriesCalculationsHilo2025sToVersion3 < ActiveRecord::Migration[7.1]
  def change
    update_view :lotteries_calculations_hilo_2025s, version: 3, revert_to_version: 2
  end
end
