class IndexLotteryEntrantsOnUniqueAttributes < ActiveRecord::Migration[6.1]
  def change
    add_index :lottery_entrants,
              [:lottery_division_id, :first_name, :last_name, :birthdate],
              unique: true,
              name: "index_lottery_index_on_unique_key_attributes"
  end
end
