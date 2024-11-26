class AddIndexOnHistoricalFactsNamesAndStateCode < ActiveRecord::Migration[7.0]
  def change
    add_index :historical_facts, [:last_name, :first_name, :state_code], name: "index_historical_facts_on_names_and_state_code"
  end
end
