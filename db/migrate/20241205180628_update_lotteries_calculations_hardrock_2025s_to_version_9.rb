class UpdateLotteriesCalculationsHardrock2025sToVersion9 < ActiveRecord::Migration[7.0]
  def change
    update_view :lotteries_calculations_hardrock_2025s, version: 9, revert_to_version: 8
  end
end
