class CreateAnalyticsSmsInboundMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :analytics_sms_inbound_messages do |t|
      t.string   :origination_number,  null: false
      t.string   :destination_number,  null: false
      t.string   :message_body,        null: false
      t.datetime :received_at,         null: false
      t.string   :sns_message_id,      null: false
      t.string   :inbound_message_id
      t.string   :keyword
      t.timestamps

      t.index :sns_message_id,    unique: true
      t.index :origination_number
      t.index :received_at
    end
  end
end
