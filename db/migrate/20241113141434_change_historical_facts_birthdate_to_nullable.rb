class ChangeHistoricalFactsBirthdateToNullable < ActiveRecord::Migration[7.0]
  def change
    change_column_null :historical_facts, :birthdate, true
  end
end
