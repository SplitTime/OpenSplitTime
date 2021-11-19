class AddStatusToLotteries < ActiveRecord::Migration[6.1]
  def change
    add_column :lotteries, :concealed, :boolean
    add_column :lotteries, :status, :integer
  end
end
