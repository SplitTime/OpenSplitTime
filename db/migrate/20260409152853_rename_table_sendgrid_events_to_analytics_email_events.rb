class RenameTableSendgridEventsToAnalyticsEmailEvents < ActiveRecord::Migration[8.1]
  def change
    rename_table :sendgrid_events, :analytics_email_events
  end
end
