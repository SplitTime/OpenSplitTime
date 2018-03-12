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
    @efforts ||= EffortPolicy::Scope.new(current_user, Effort).viewable.includes(:event, split_times: :split)
                     .where(person: person).sort_by { |effort| -effort.start_time.to_i }
  end

  def method_missing(method)
    person.send(method)
  end

  private

  attr_reader :params, :current_user
end
