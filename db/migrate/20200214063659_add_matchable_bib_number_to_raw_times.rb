class AddMatchableBibNumberToRawTimes < ActiveRecord::Migration[5.2]
  def up
    add_column :raw_times, :matchable_bib_number, :integer
    RawTime.find_each(&:save!)
  end

  def down
    remove_column :raw_times, :matchable_bib_number, :integer
  end
end
