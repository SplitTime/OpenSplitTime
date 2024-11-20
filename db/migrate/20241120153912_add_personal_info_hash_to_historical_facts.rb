class AddPersonalInfoHashToHistoricalFacts < ActiveRecord::Migration[7.0]
  def change
    add_column :historical_facts, :personal_info_hash, :string
    add_index :historical_facts, :personal_info_hash
  end
end
