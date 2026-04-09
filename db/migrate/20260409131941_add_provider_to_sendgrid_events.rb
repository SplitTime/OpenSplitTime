class AddProviderToSendgridEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :sendgrid_events, :provider, :string, null: false, default: "sendgrid"
    rename_column :sendgrid_events, :sg_event_id, :provider_event_id
    rename_column :sendgrid_events, :sg_message_id, :provider_message_id
  end
end
