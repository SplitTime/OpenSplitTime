class UpdateLotteriesCalculationsHardrock2025sToVersion2 < ActiveRecord::Migration[7.0]
  def change
    update_view :lotteries_calculations_hardrock_2025s, version: 2, revert_to_version: 1
  end
end
