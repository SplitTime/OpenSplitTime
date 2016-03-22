class EventSplitPolicy
  attr_reader :current_user, :model

  def initialize(current_user, model)
    @current_user = current_user
    @event_split = model
  end

  def destroy?
    @current_user.authorized_to_edit?(@event_split.event)
  end

end
