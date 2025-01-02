class EventGroupWebhooksPresenter < BasePresenter
  attr_reader :event_group, :current_user

  delegate :name, :organization, :organization_name, :events, :home_time_zone, :scheduled_start_time_local, :available_live,
           :multiple_events?, to: :event_group

  def initialize(event_group, view_context)
    @event_group = event_group
    @params = view_context.params
    @current_user = view_context.current_user
    refresh_pending_subscriptions
  end

  def event
    event_group.first_event
  end

  def event_group_finished?
    event_group.finished?
  end

  def subscriptions_pending?
    current_user.subscriptions.where(subscribable: events).pending.any?
  end

  def webhooks_available?
    events.having_topic_resource_key.any?
  end

  private

  def refresh_pending_subscriptions
    event_group.events.each do |event|
      event.subscriptions.for_user(current_user).pending.each do |subscription|
        subscription.save
      end
    end
  end
end
