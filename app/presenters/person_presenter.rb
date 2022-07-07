# frozen_string_literal: true

class PersonPresenter < BasePresenter
  attr_reader :person

  delegate :to_param, to: :person

  def initialize(person, params, current_user)
    @person = person
    @params = params
    @current_user = current_user
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

  private

  attr_reader :params, :current_user
end
