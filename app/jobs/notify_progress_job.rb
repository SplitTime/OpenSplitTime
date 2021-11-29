# frozen_string_literal: true

class NotifyProgressJob < ApplicationJob
  def perform(effort_id, split_time_ids)
    @effort_id = effort_id
    @split_time_ids = split_time_ids
    return unless split_time_ids.compact.present? && split_times.present? && effort.present?
    return if effort_not_notifiable? || notification_not_timely? || farther_notification_exists?

    response = ProgressNotifier.publish(topic_arn: topic_resource_key, effort_data: progress_data)

    if response.successful?
      notification = Notification.new(kind: :progress, effort: effort, distance: farthest_split_time.total_distance,
                                      bitkey: farthest_split_time.bitkey, follower_ids: followers.ids,
                                      subject: response.resources[:subject], notice_text: response.resources[:notice_text],
                                      topic_resource_key: effort.topic_resource_key)
      unless notification.save
        logger.error "  Unable to create notification for #{st.effort} at #{st.total_distance}"
        logger.error "  #{notification.errors.full_messages}"
      end
    else
      logger.error response.error_report
    end
  end

  private

  attr_reader :effort_id, :split_time_ids
  delegate :topic_resource_key, to: :effort

  def effort
    @effort ||= Effort.where(id: effort_id).includes(:event, split_times: {split: :course}).first
  end

  def split_times
    @split_times ||= effort.ordered_split_times.select { |st| st.id.in?(split_time_ids) }
  end

  def followers
    @followers ||= effort.followers
  end

  def effort_not_notifiable?
    effort.topic_resource_key.blank?
  end

  def notification_not_timely?
    latest_absolute_time < earliest_notification_time
  end

  def latest_absolute_time
    @latest_absolute_time ||= split_times.map(&:absolute_time).max
  end

  def earliest_notification_time
    6.hours.ago
  end

  def farther_notification_exists?
    farthest_notification &&
        ([farthest_notification.distance, farthest_notification.bitkey] <=>
            [farthest_split_time.total_distance, farthest_split_time.bitkey]) > 0
  end

  def farthest_notification
    Notification.where(kind: :progress, effort: effort).order(distance: :desc, bitkey: :desc).limit(1).first
  end

  def farthest_split_time
    split_times.last
  end

  def progress_data
    EffortProgressData.new(effort: effort, split_times: split_times).effort_data
  end
end
