class RenameTableSendgridEventsToEmailEvents < ActiveRecord::Migration[8.1]
  def change
    rename_table :sendgrid_events, :email_events
  end
end
