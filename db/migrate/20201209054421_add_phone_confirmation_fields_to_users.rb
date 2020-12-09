class AddPhoneConfirmationFieldsToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :phone_confirmation_token, :string
    add_column :users, :phone_confirmed_at, :datetime
    add_column :users, :phone_confirmation_sent_at, :datetime
  end
end
