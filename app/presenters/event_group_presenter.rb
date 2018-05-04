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
    @events ||= event_group.events.select_with_params('').order(:start_time).to_a
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
    @authorized_to_edit ||= current_user&.authorized_to_edit?(event_group)
  end

  def show_visibility_columns?
    authorized_to_edit?
  end

  def finish_live_times
    finish_splits = Split.joins(:events).where(events: {event_group_id: event_group.id}, kind: :finish)
    event_group.live_times.includes(:event).where(split_id: finish_splits)
  end

  def method_missing(method)
    event_group.send(method)
  end

  private

  attr_reader :params, :current_user
end
