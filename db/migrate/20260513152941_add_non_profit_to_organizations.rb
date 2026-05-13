class AddNonProfitToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :non_profit, :boolean, default: false, null: false
  end
end
