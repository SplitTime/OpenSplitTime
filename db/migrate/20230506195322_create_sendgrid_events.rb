class CreateSendgridEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :sendgrid_events do |t|
      t.string :email
      t.datetime :timestamp
      t.string :smtp_id
      t.string :event
      t.string :category
      t.string :sg_event_id
      t.string :sg_message_id
      t.string :reason
      t.string :status
      t.string :ip
      t.string :response
      t.string :type
      t.string :useragent

      t.timestamps
    end
  end
end
