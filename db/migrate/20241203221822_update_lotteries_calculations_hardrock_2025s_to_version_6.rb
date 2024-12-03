class UpdateLotteriesCalculationsHardrock2025sToVersion6 < ActiveRecord::Migration[7.0]
  def change
    update_view :lotteries_calculations_hardrock_2025s, version: 6, revert_to_version: 5
  end
end
