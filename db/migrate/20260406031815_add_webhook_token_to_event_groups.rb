class AddWebhookTokenToEventGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :event_groups, :webhook_token, :string
    add_index :event_groups, :webhook_token, unique: true
  end
end
