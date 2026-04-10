class ChangeDefaultTypeOnAnalyticsEmailEvents < ActiveRecord::Migration[8.1]
  def change
    change_column_default :analytics_email_events, :type, from: "Analytics::SendgridEvent", to: nil
  end
end
