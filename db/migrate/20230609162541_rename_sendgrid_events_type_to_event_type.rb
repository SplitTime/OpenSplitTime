class RenameSendgridEventsTypeToEventType < ActiveRecord::Migration[7.0]
  def change
    rename_column :sendgrid_events, :type, :event_type
  end
end
