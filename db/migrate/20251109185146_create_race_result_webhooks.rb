# frozen_string_literal: true

class CreateRaceResultWebhooks < ActiveRecord::Migration[7.2]
  def change
    create_table :race_result_webhooks do |t|
      # Identifiers from RaceResult
      t.string :event_id, null: false, index: true
      t.string :webhook_id, null: false
      t.string :trigger_type, null: false
      
      # Timing information
      t.datetime :webhook_timestamp, null: false
      
      # Full payload storage
      t.jsonb :payload, null: false, default: {}
      
      # Request metadata
      t.string :source_ip
      t.text :user_agent
      t.string :request_method, default: 'POST'
      
      # Processing status
      t.string :status, default: 'received', null: false
      t.text :error_message
      t.datetime :processed_at
      
      # OpenSplitTime associations (for future use)
      t.references :event, foreign_key: true, null: true
      t.references :effort, foreign_key: true, null: true
      t.references :split_time, foreign_key: true, null: true
      
      t.timestamps
    end
    
    # Indexes for common queries
    add_index :race_result_webhooks, :webhook_timestamp
    add_index :race_result_webhooks, :trigger_type
    add_index :race_result_webhooks, :status
    add_index :race_result_webhooks, [:event_id, :webhook_timestamp]
    add_index :race_result_webhooks, :payload, using: :gin
  end
end