class RenameInterestToConnection < ActiveRecord::Migration
  def change
    rename_table :interests, :connections
  end
end
