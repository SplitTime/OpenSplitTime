class UpdateLotteriesCalculationsHardrock2025sToVersion3 < ActiveRecord::Migration[7.0]
  def change
    update_view :lotteries_calculations_hardrock_2025s, version: 3, revert_to_version: 2
  end
end
