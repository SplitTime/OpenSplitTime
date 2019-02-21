class AddEventSeriesToEvents < ActiveRecord::Migration[5.2]
  def change
    add_reference :events, :event_series
  end
end
