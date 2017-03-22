class AddResourceKeyToSubscriptions < ActiveRecord::Migration
  def self.up
    remove_column :subscriptions, :kind, :integer, default: 0, null: false
    add_column :subscriptions, :protocol, :integer, default: 0, null: false
    add_column :subscriptions, :resource_key, :string
    remove_index :subscriptions, column: [:user_id, :participant_id], unique: true
    add_index :subscriptions, :resource_key, unique: true
    add_index :subscriptions, [:user_id, :participant_id, :protocol], unique: true
  end

  def self.down
    remove_index :subscriptions, column: [:user_id, :participant_id, :protocol]
    remove_index :subscriptions, column: :resource_key
    subs = Subscription.where.not(protocol: 0)
    subs.delete_all
    add_index :subscriptions, [:user_id, :participant_id], unique: true
    remove_column :subscriptions, :resource_key
    remove_column :subscriptions, :protocol
    add_column :subscriptions, :kind, :integer, default: 0, null: false
  end
end
