class CreateEventGroups < ActiveRecord::Migration[5.0]
  def change
    create_table :event_groups do |t|
      t.string :name, null: false
      t.boolean :available_live, default: false
      t.boolean :auto_live_times, default: false
      t.boolean :concealed, default: false

      t.timestamps null: false
      t.integer :created_by
      t.integer :updated_by
    end
  end
end
