class NotifyEventUpdateJob < ApplicationJob
  queue_as :default

  def perform(event_id)
    @event_id = event_id
    return unless event_id.present? && event.present?

    response = EventUpdateNotifier.publish(topic_arn: topic_resource_key, event: event)

    return if response.successful?

    raise "Failed to send event update notification for #{event.name} (#{event.id}): " \
          "#{response.message_with_error_report}"
  end

  private

  attr_reader :event_id

  delegate :topic_resource_key, to: :event

  def event
    return @event if defined?(@event)

    @event = Event.find_by(id: event_id)
  end
end
