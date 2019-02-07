# frozen_string_literal: true

class NotifyProgressJob < ApplicationJob
  def perform(args)
    ArgsValidator.validate(params: args,
                           required: [:effort_id, :split_time_ids],
                           exclusive: [:effort_id, :split_time_ids, :multi_lap],
                           class: self)
    effort_id = args[:effort_id]
    split_time_ids = args[:split_time_ids]

    return unless effort_id.present? && split_time_ids.compact.present?

    live_data = EffortProgressData.new(effort_id: effort_id, split_time_ids: split_time_ids)
    return if live_data.split_times.empty? || farther_notification_exists?(live_data.split_times.last)

    response = ProgressNotifier.publish(topic_arn: live_data.topic_resource_key, effort_data: live_data.effort_data)

    if response.successful?
      live_data.split_times.each do |split_time|
        notification = Notification.new(kind: :progress, effort: split_time.effort, distance: split_time.total_distance,
                                        bitkey: split_time.bitkey, follower_ids: live_data.followers.ids,
                                        subject: response.resources[:subject], notice_text: response.resources[:notice_text],
                                        topic_resource_key: response.resources[:topic_resource_key])
        unless notification.save
          logger.error "Unable to create notification for #{split_time.effort} at #{split_time.total_distance}"
          logger.error notification.errors.full_messages
        end
      end
    end
  end

  private

  def farther_notification_exists?(split_time)
    farthest_notification = farthest_notification(split_time.effort)
    return false unless farthest_notification
    proposed_distance = split_time.total_distance

    farthest_notification.distance > proposed_distance ||
        (farthest_notification.distance == proposed_distance && farthest_notification.bitkey > split_time.bitkey)
  end

  def farthest_notification(effort)
    Notification.where(effort: effort).order(distance: :desc, bitkey: :desc).limit(1).first
  end
end
