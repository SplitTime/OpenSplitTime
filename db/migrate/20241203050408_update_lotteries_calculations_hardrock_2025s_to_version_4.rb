class UpdateLotteriesCalculationsHardrock2025sToVersion4 < ActiveRecord::Migration[7.0]
  def change
    update_view :lotteries_calculations_hardrock_2025s, version: 4, revert_to_version: 3
  end
end
