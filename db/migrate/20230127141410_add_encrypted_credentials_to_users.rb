class AddEncryptedCredentialsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :credentials, :json
  end
end
