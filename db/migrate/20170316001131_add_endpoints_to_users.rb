class AddEndpointsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :phone, :string
    add_column :users, :http_endpoint, :string
    add_column :users, :https_endpoint, :string
  end
end
