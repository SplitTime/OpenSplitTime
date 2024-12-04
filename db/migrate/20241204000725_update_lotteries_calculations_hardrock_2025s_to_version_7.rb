class UpdateLotteriesCalculationsHardrock2025sToVersion7 < ActiveRecord::Migration[7.0]
  def change
    update_view :lotteries_calculations_hardrock_2025s, version: 7, revert_to_version: 6
  end
end
