# frozen_string_literal: true

class EventGroupNotificationsPresenter < BasePresenter
  attr_reader :event_group
  delegate :efforts, :name, :organization, :events, :home_time_zone, :start_time_local, :available_live,
           :concealed?, :multiple_events?, to: :event_group

  def initialize(event_group)
    @event_group = event_group
  end

  def distances_noticed_count
    notifications.group(:distance).count.keys.size
  end

  def efforts_noticed_count
    notifications.group(:effort_id).count.keys.size
  end

  def notifications_count
    notifications.pluck(:follower_ids).flatten.uniq.size
  end

  def subscriptions_count
    Subscription.where(subscribable_type: 'Effort', subscribable_id: efforts).count
  end

  def event
    event_group.first_event
  end

  private

  def notifications
    @notifications = Notification.where(effort: efforts).where.not(follower_ids: [])
  end
end
