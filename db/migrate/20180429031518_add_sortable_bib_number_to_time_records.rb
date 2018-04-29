class AddSortableBibNumberToTimeRecords < ActiveRecord::Migration[5.1]
  def up
    add_column :raw_times, :sortable_bib_number, :integer
    RawTime.find_each(&:save!)
    change_column_null :raw_times, :sortable_bib_number, false

    add_column :live_times, :sortable_bib_number, :integer
    LiveTime.find_each(&:save!)
    change_column_null :live_times, :sortable_bib_number, false
  end

  def down
    remove_column :raw_times, :sortable_bib_number, :integer
    remove_column :live_times, :sortable_bib_number, :integer
  end
end
