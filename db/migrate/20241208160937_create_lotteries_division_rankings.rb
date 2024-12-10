class CreateLotteriesDivisionRankings < ActiveRecord::Migration[7.0]
  def change
    create_view :lotteries_division_rankings
  end
end
