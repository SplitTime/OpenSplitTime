class RenameConnectionsToSubscriptions < ActiveRecord::Migration
  def change
    rename_table :connections, :subscriptions
  end
end
