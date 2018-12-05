class RemoveUniquenessFromSubscriptionsIndex < ActiveRecord::Migration[5.1]
  def change
    remove_index :subscriptions, :resource_key
    add_index :subscriptions, :resource_key, unique: false
  end
end
