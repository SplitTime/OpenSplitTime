class AddSmsCarrierOptedOutAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :sms_carrier_opted_out_at, :datetime
    add_index :users, :sms_carrier_opted_out_at
  end
end
