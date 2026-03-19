class CreateSolidCableMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :solid_cable_messages do |t|
      t.binary :channel, null: false, limit: 1024
      t.binary :payload, null: false, limit: 536870912
      t.datetime :created_at, null: false
      t.integer :channel_hash, null: false, limit: 8

      t.index :channel
      t.index :channel_hash
      t.index :created_at
    end
  end
end
