class UpdateLotteriesCalculationsHardrock2025sToVersion5 < ActiveRecord::Migration[7.0]
  def change
    update_view :lotteries_calculations_hardrock_2025s, version: 5, revert_to_version: 4
  end
end
