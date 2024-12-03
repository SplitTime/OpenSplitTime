class AddExternalIdToHistoricalFacts < ActiveRecord::Migration[7.0]
  def change
    add_column :historical_facts, :external_id, :string
  end
end
