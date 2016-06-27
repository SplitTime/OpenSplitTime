class RenameOwnershipToStewardship < ActiveRecord::Migration
  def change
    rename_table :ownerships, :stewardships
  end
end
