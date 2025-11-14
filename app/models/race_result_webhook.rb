# frozen_string_literal: true

# == Schema Information
#
# Table name: race_result_webhooks
#
#  id                 :bigint           not null, primary key
#  event_id           :string           not null
#  webhook_id         :string           not null
#  trigger_type       :string           not null
#  webhook_timestamp  :datetime         not null
#  payload            :jsonb            not null
#  source_ip          :string
#  user_agent         :text
#  request_method     :string           default("POST")
#  status             :string           default("received"), not null
#  error_message      :text
#  processed_at       :datetime
#  event_id           :bigint
#  effort_id          :bigint
#  split_time_id      :bigint
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class RaceResultWebhook < ApplicationRecord
  # Associations
  belongs_to :event, optional: true
  belongs_to :effort, optional: true
  belongs_to :split_time, optional: true
  
  # Validations
  validates :rr_event_id, presence: true
  validates :webhook_id, presence: true
  validates :trigger_type, presence: true
  validates :webhook_timestamp, presence: true
  validates :payload, presence: true
  validates :status, presence: true, inclusion: { 
    in: %w[received processing processed failed] 
  }
  
  # Scopes
  scope :received, -> { where(status: 'received') }
  scope :processing, -> { where(status: 'processing') }
  scope :processed, -> { where(status: 'processed') }
  scope :failed, -> { where(status: 'failed') }
  scope :recent, -> { order(webhook_timestamp: :desc) }
  scope :by_event, ->(event_id) { where(event_id: event_id) }
  scope :by_trigger, ->(trigger_type) { where(trigger_type: trigger_type) }
  scope :unprocessed, -> { where(status: 'received') }
  
  # Class methods
  def self.log_webhook(params)
    create!(
      rr_event_id: params[:event_id],
      webhook_id: params[:webhook_id],
      trigger_type: params[:trigger] || params[:trigger_type] || 'unknown',
      webhook_timestamp: params[:timestamp] || Time.current,
      payload: params.to_h,
      source_ip: params[:source_ip],
      user_agent: params[:user_agent],
      status: 'received'
    )
  rescue StandardError => e
    Rails.logger.error("Failed to log RaceResult webhook: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    nil
  end
  
  # Instance methods
  def mark_as_processing!
    update!(status: 'processing', processed_at: Time.current)
  end
  
  def mark_as_processed!
    update!(status: 'processed', processed_at: Time.current)
  end
  
  def mark_as_failed!(error)
    update!(
      status: 'failed', 
      error_message: error.message,
      processed_at: Time.current
    )
  end
  
  def participant_data
    payload.dig('participant') || {}
  end
  
  def raw_data
    payload.dig('raw_data') || {}
  end
  
  def timing_data
    raw_data
  end
  
  def bib_number
    participant_data['bib_number'] || raw_data['bib_number']
  end
  
  def split_name
    raw_data['split_name']
  end
  
  def absolute_time
    return nil unless raw_data['absolute_time']
    Time.parse(raw_data['absolute_time'])
  rescue ArgumentError
    nil
  end
  
  def new_participant?
    trigger_type == 'new_participant'
  end
  
  def participant_update?
    trigger_type == 'participant_update'
  end
  
  def new_raw_data?
    trigger_type == 'new_raw_data'
  end
  
  def event_setting_changed?
    trigger_type == 'event_file_setting_changed'
  end
  
  def to_s
    "RaceResult Webhook ##{id} - #{trigger_type} for Event #{event_id} at #{webhook_timestamp}"
  end
end