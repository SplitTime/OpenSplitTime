class EventGroupPresenter < BasePresenter
  attr_reader :event_group
  delegate :to_param, to: :event_group

  def initialize(event_group, params, current_user)
    @event_group = event_group
    @params = params
    @current_user = current_user
  end

  def events
    @events ||= EventPolicy::Scope.new(current_user, Event).viewable
                     .where(event_group: event_group).select_with_params('')
  end

  def authorized_to_edit?
    current_user&.authorized_to_edit?(event_group)
  end

  def method_missing(method)
    event_group.send(method)
  end

  private

  attr_reader :params, :current_user
end
