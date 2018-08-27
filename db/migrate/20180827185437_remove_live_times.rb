class RemoveLiveTimes < ActiveRecord::Migration[5.1]
  def up
    drop_table :live_times
  end

  def down
    create_table :live_times do |t|
      t.references "event", null: false
      t.references "split", null: false
      t.references "split_time"
      t.string "bib_number", null: false
      t.integer "sortable_bib_number", null: false
      t.integer "bitkey", null: false
      t.string "source", null: false
      t.string "wave"
      t.datetime "absolute_time"
      t.string "entered_time"
      t.boolean "with_pacer"
      t.boolean "stopped_here"
      t.string "remarks"
      t.string "batch"
      t.integer "created_by"
      t.integer "updated_by"
      t.integer "pulled_by"
      t.datetime "pulled_at"

      t.timestamps
    end
  end
end
