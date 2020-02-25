# frozen_string_literal: true

class EventGroupStatsPresenter < BasePresenter
  attr_reader :event_group
  delegate :efforts, :name, :organization, :events, :home_time_zone, :start_time_local, :available_live,
           :concealed?, :multiple_events?, to: :event_group

  def initialize(event_group)
    @event_group = event_group
  end

  def ranked_efforts
    @ranked_efforts ||= efforts.ranked_with_status
  end

  def event
    event_group.first_event
  end

  def noticed_efforts_with_count
    @noticed_efforts_with_count ||=
      efforts.joins(:notifications)
        .select("efforts.*, sum(array_length(notifications.follower_ids, 1)) as notifications_count")
        .where.not(notifications: {follower_ids: []})
        .group("efforts.id")
        .order(notifications_count: :desc).to_a
  end

  def stats_available?
    total_distance.positive?
  end

  def subs_count_by_protocol
    @subs_count_by_protocol ||=
      Subscription.where(subscribable_type: 'Effort', subscribable_id: efforts).group(:protocol).count
  end

  def total_distance
    ranked_efforts.map(&:final_distance).compact.sum
  end

  def total_laps
    ranked_efforts.map(&:final_lap).compact.sum
  end

  def total_vert_gain
    ranked_efforts.map(&:final_vert_gain).compact.sum
  end

  def total_noticed_efforts_count
    noticed_efforts_with_count.size
  end

  def total_notifications_count
    noticed_efforts_with_count.map(&:notifications_count).sum
  end

  def total_subscriptions_count
    subs_count_by_protocol.values.sum
  end
end
