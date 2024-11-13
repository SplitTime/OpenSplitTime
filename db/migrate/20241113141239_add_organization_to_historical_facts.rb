class AddOrganizationToHistoricalFacts < ActiveRecord::Migration[7.0]
  def change
    add_reference :historical_facts, :organization, foreign_key: true, null: false
  end
end
