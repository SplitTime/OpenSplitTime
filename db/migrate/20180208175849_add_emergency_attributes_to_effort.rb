class AddEmergencyAttributesToEffort < ActiveRecord::Migration[5.1]
  def change
    add_column :efforts, :emergency_contact, :string
    add_column :efforts, :emergency_phone, :string
  end
end
