class AddLevelToStewardships < ActiveRecord::Migration
  def change
    add_column :stewardships, :level, :integer, default: 0
  end
end
