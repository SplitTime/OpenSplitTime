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

  def participation_notifiable?
    person.topic_resource_key.present?
  end

  def method_missing(method)
    person.send(method)
  end
end
