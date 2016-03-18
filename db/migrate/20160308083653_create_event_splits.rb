class CreateEventSplits < ActiveRecord::Migration
  def change
    create_table :event_splits do |t|
      t.references :event, index: true, foreign_key: true
      t.references :split, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
