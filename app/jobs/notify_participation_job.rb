# frozen_string_literal: true

class NotifyParticipationJob < ApplicationJob
  def perform(effort_id)
    @effort_id = effort_id

    return unless effort_id.present? && effort.present? && person.present? && event.present?
    return if notification_exists?

    response = ParticipationNotifier.publish(topic_arn: topic_resource_key, event: event)

    if response.successful?
      notification = Notification.new(kind: :participation, effort: effort, follower_ids: person.followers.ids,
                                      subject: response.resources[:subject], notice_text: response.resources[:notice_text],
                                      topic_resource_key: topic_resource_key)
      unless notification.save
        logger.error "  Unable to create notification for #{effort} at #{event}"
        logger.error "  #{notification.errors.full_messages}"
      end
    end
  end

  private

  attr_reader :effort_id
  delegate :person, :event, to: :effort
  delegate :topic_resource_key, to: :person

  def notification_exists?
    Notification.find_by(kind: :participation, effort: effort).present?
  end

  def effort
    @effort ||= Effort.where(id: effort_id).includes(:event, :person, split_times: {split: :course}).first
  end
end
