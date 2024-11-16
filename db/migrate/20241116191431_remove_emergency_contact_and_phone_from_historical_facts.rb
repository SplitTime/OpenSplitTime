class RemoveEmergencyContactAndPhoneFromHistoricalFacts < ActiveRecord::Migration[7.0]
  def change
    remove_column :historical_facts, :emergency_contact, :string
    remove_column :historical_facts, :emergency_phone, :string
  end
end
