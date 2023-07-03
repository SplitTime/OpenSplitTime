# frozen_string_literal: true

class NotifyEventUpdateJob < ApplicationJob
  def perform(event_id)
    @event_id = event_id

    return unless event_id.present? && event.present?

    response = EventUpdateNotifier.publish(topic_arn: topic_resource_key, event: event)

    if response.successful?
      notification = Notification.new(kind: :event_update, event: event, follower_ids: event.followers.ids,
                                      subject: response.resources[:subject], notice_text: response.resources[:notice_text],
                                      topic_resource_key: topic_resource_key)
      unless notification.save
        logger.error "  Unable to create notification for #{event}"
        logger.error "  #{notification.errors.full_messages}"
      end
    end
  end

  private

  attr_reader :event_id

  delegate :topic_resource_key, to: :event

  def event
    @event ||= Event.find_by(id: event_id)
  end
end
