class AddEndpointToSubscriptions < ActiveRecord::Migration[7.0]
  def change
    add_column :subscriptions, :endpoint, :string
  end
end
