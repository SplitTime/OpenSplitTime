class AddYearToHistoricalFacts < ActiveRecord::Migration[7.0]
  def change
    add_column :historical_facts, :year, :integer
  end
end
