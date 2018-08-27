# frozen_string_literal: true

class NotifyFollowersJob < ApplicationJob
  def perform(args)
    ArgsValidator.validate(params: args,
                           required: [:person_id, :split_time_ids],
                           exclusive: [:person_id, :split_time_ids, :multi_lap],
                           class: self)
    person_id = args[:person_id]
    split_time_ids = args[:split_time_ids]

    return unless person_id.present? && split_time_ids.compact.present?

    live_data = LiveEffortMailData.new(person_id: person_id, split_time_ids: split_time_ids)
    return if live_data.split_times.empty? || farther_notification_exists?(live_data.split_times.last)

    response = FollowerNotifier.publish(topic_arn: live_data.topic_resource_key, effort_data: live_data.effort_data)
    if response.successful?
      live_data.split_times.each do |split_time|
        notification = Notification.new(effort: split_time.effort, distance: split_time.distance_from_start, bitkey: split_time.bitkey, follower_ids: live_data.followers.ids)
        unless notification.save
          logger.info "Unable to create notification for #{split_time.effort} at #{split_time.distance_from_start}"
          logger.info notification.errors.full_messages
        end
      end
    end
  end

  private

  def farther_notification_exists?(split_time)
    farthest_notification = farthest_notification(split_time.effort)
    return false unless farthest_notification

    proposed_distance = split_time.lap_split.distance_from_start

    farthest_notification.distance > proposed_distance ||
        (farthest_notification.distance == proposed_distance && farthest_notification.bitkey > split_time.bitkey)
  end

  def farthest_notification(effort)
    Notification.where(effort: effort).order(distance: :desc, bitkey: :desc).limit(1).first
  end
end
