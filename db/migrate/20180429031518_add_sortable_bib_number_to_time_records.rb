class AddSortableBibNumberToTimeRecords < ActiveRecord::Migration[5.1]
  def up
    add_column :raw_times, :sortable_bib_number, :integer
  end

  def down
    remove_column :raw_times, :sortable_bib_number, :integer
  end
end
