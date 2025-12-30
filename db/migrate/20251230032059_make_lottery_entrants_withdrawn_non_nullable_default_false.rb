class MakeLotteryEntrantsWithdrawnNonNullableDefaultFalse < ActiveRecord::Migration[7.2]
  def up
    execute <<~SQL
      UPDATE lottery_entrants
      SET withdrawn = false
      WHERE withdrawn IS NULL;
    SQL

    change_column_default :lottery_entrants, :withdrawn, false
    change_column_null :lottery_entrants, :withdrawn, false
  end

  def down
    change_column_null :lottery_entrants, :withdrawn, true
    change_column_default :lottery_entrants, :withdrawn, nil
  end
end
