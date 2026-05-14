class PersonPresenter < BasePresenter
  attr_reader :person, :current_user

  delegate :to_param, to: :person

  def initialize(person, view_context)
    @person = person
    @current_user = view_context.current_user
  end

  def efforts
    @efforts ||= EffortPolicy::Scope.new(current_user, person.efforts)
                                    .viewable
                                    .includes(event: :event_group)
                                    .joins(:event)
                                    .finish_info_subquery
                                    .order("events.scheduled_start_time desc")
  end

  def method_missing(method, ...)
    if person.respond_to?(method)
      person.send(method, ...)
    else
      super
    end
  end

  def respond_to_missing?(method, include_private = false)
    person.respond_to?(method, include_private) || super
  end
end
