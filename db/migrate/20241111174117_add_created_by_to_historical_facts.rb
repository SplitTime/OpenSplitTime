class AddCreatedByToHistoricalFacts < ActiveRecord::Migration[7.0]
  def change
    add_column :historical_facts, :created_by, :integer
  end
end
