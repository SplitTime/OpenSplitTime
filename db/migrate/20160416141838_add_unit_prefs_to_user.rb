class AddUnitPrefsToUser < ActiveRecord::Migration
  def change
    add_column :users, :pref_distance_unit, :integer, default: 0, null: false
    add_column :users, :pref_elevation_unit, :integer, default: 0, null: false
  end
end
