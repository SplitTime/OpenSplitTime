class RemoveEventFromHistoricalFacts < ActiveRecord::Migration[7.0]
  def change
    remove_reference :historical_facts, :event, foreign_key: true
  end
end
