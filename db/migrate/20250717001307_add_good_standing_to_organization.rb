class AddGoodStandingToOrganization < ActiveRecord::Migration[7.1]
  def change
    add_column :organizations, :good_standing, :boolean, default: false
  end
end
