class PersonPresenter < BasePresenter

  delegate :to_param, to: :person

  def initialize(person, params, current_user)
    @person = person
    @params = params
    @current_user = current_user
  end

  def efforts
    @efforts ||= EffortPolicy::Scope.new(current_user, Effort).viewable.with_ordered_split_times
                     .where(person: person).sort_by { |effort| -effort.start_time.to_i }
  end

  def method_missing(method)
    person.send(method)
  end

  private

  attr_reader :person, :params, :current_user
end
