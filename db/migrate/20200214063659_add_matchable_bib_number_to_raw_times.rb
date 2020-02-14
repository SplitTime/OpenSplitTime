class AddMatchableBibNumberToRawTimes < ActiveRecord::Migration[5.2]
  def change
    add_column :raw_times, :matchable_bib_number, :integer
  end
end
