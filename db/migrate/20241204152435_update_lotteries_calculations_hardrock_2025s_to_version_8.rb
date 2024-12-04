class UpdateLotteriesCalculationsHardrock2025sToVersion8 < ActiveRecord::Migration[7.0]
  def change
    update_view :lotteries_calculations_hardrock_2025s, version: 8, revert_to_version: 7
  end
end
