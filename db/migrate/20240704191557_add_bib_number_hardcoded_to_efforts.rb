class AddBibNumberHardcodedToEfforts < ActiveRecord::Migration[7.0]
  def change
    add_column :efforts, :bib_number_hardcoded, :boolean
  end
end
