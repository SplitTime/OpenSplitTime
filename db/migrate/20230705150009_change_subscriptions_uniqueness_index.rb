class ChangeSubscriptionsUniquenessIndex < ActiveRecord::Migration[7.0]
  def change
    remove_index :subscriptions, [:user_id, :subscribable_type, :subscribable_id, :protocol], unique: true, name: "index_subscriptions_on_unique_fields"
    add_index :subscriptions, [:user_id, :subscribable_type, :subscribable_id, :protocol, :endpoint], unique: true, name: "index_subscriptions_on_unique_fields_with_endpoint"
  end
end
