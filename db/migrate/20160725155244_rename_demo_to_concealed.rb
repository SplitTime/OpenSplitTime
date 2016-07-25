class RenameDemoToConcealed < ActiveRecord::Migration
  def change
    rename_column :races, :demo, :concealed
    rename_column :events, :demo, :concealed
    rename_column :efforts, :demo, :concealed
    rename_column :participants, :demo, :concealed
  end
end
