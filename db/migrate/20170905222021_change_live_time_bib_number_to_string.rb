class ChangeLiveTimeBibNumberToString < ActiveRecord::Migration[5.0]
  def change
    change_column :live_times, :bib_number, :string
  end
end
