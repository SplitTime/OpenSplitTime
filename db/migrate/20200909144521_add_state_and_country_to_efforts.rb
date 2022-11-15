class AddStateAndCountryToEfforts < ActiveRecord::Migration[5.2]
  def change
    add_column :efforts, :state_name, :string
    add_column :efforts, :country_name, :string
  end
end
