class MakeSubscriptionsPolymorphic < ActiveRecord::Migration[5.2]
  def up
    remove_index :subscriptions, [:user_id, :person_id, :protocol]

    add_column :subscriptions, :subscribable_type, :string
    rename_column :subscriptions, :person_id, :subscribable_id

    Subscription.update_all(subscribable_type: 'Person')

    change_column_null :subscriptions, :subscribable_type, false
    add_index :subscriptions, [:subscribable_type, :subscribable_id]
    add_index :subscriptions, [:user_id, :subscribable_type, :subscribable_id, :protocol], name: 'index_subscriptions_on_unique_fields', unique: true
  end

  def down
    remove_index :subscriptions, [:subscribable_type, :subscribable_id]
    remove_index :subscriptions, [:user_id, :subscribable_type, :subscribable_id, :protocol]

    rename_column :subscriptions, :subscribable_id, :person_id
    remove_column :subscriptions, :subscribable_type

    add_index :subscriptions, [:user_id, :person_id, :protocol], unique: true
  end
end
