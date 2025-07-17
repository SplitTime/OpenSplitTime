class AddGoodStandingToOrganization < ActiveRecord::Migration[7.1]
  def change
    add_column :organizations, :good_standing_through, :date
  end
end
