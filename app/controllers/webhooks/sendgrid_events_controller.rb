# frozen_string_literal: true

class Webhooks::SendgridEventsController < ::ApplicationController
  def create
    status = :ok
    rows = params.require(:_json)

    rows.each do |row|
      sendgrid_event = SendgridEvent.new(row.permit(*sendgrid_event_params))
      unless sendgrid_event.save
        status = :unprocessable_entity
        break
      end
    end

    head status
  rescue ActionController::ParameterMissing
    head :unprocessable_entity
  end

  private

  def sendgrid_event_params
    [
      :email,
      :timestamp,
      :smtp_id,
      :event,
      :category,
      :sg_event_id,
      :sg_message_id,
      :reason,
      :status,
      :ip,
      :response,
      :type,
      :useragent,
    ]
  end
end
