class ChangeEventSeriesEventsToHasManyThrough < ActiveRecord::Migration[5.2]
  def change
    remove_reference :events, :event_series

    create_table :event_series_events do |t|
      t.references :event, foreign_key: true, nil: false
      t.references :event_series, foreign_key: true, nil: false

      t.timestamps
    end
  end
end
