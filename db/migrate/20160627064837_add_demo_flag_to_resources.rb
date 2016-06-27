class AddDemoFlagToResources < ActiveRecord::Migration
  def change
    add_column :races, :demo, :boolean, default: false
    add_column :events, :demo, :boolean, default: false
    add_column :efforts, :demo, :boolean, default: false
    add_column :participants, :demo, :boolean, default: false
  end
end
