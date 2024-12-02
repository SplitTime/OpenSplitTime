class AddCalculationClassToLotteries < ActiveRecord::Migration[7.0]
  def change
    add_column :lotteries, :calculation_class, :string
  end
end
