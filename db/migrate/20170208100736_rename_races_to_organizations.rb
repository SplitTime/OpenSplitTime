class RenameRacesToOrganizations < ActiveRecord::Migration
  def change
    rename_table :races, :organizations
    rename_column :events, :race_id, :organization_id
    rename_column :stewardships, :race_id, :organization_id
  end
end