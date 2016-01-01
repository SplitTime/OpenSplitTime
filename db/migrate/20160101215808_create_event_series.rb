class CreateEventSeries < ActiveRecord::Migration
  def change
    create_table :event_series do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end
