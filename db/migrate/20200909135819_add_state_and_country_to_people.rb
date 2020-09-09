class AddStateAndCountryToPeople < ActiveRecord::Migration[5.2]
  def change
    add_column :people, :state_name, :string
    add_column :people, :country_name, :string
  end
end
