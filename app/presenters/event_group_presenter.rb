# frozen_string_literal: true

class EventGroupPresenter < BasePresenter
  attr_reader :event_group
  delegate :to_param, to: :event_group
  delegate :podium_template, to: :event

  CANDIDATE_SEPARATION_LIMIT = 7.days

  def initialize(event_group, params, current_user)
    @event_group = event_group
    @params = params
    @current_user = current_user
  end

  def events
    @events ||= EventPolicy::Scope.new(current_user, Event).viewable
                     .where(event_group: event_group).select_with_params('').order(:start_time).to_a
  end

  def event_group_names
    events.map(&:name).to_sentence(two_words_connector: ' and ', last_word_connector: ', and ')
  end

  def event
    events.first
  end

  def candidate_events
    (organization.events.select_with_params('').order(start_time: :desc) - events)
        .select { |event| (event.start_time - events.first.start_time).abs < CANDIDATE_SEPARATION_LIMIT }
  end

  def authorized_to_edit?
    current_user&.authorized_to_edit?(event_group)
  end

  def show_visibility_columns?
    authorized_to_edit?
  end

  def method_missing(method)
    event_group.send(method)
  end

  private

  attr_reader :params, :current_user
end
