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

  def ranked_efforts
    event_group_efforts.ranked_with_status(sort: sort_hash)
  end

  def filtered_ranked_efforts
    @filtered_ranked_efforts ||=
        ranked_efforts
            .select { |effort| filtered_ids.include?(effort.id) && matches_criteria?(effort) }
            .paginate(page: page, per_page: per_page)
  end

  def filtered_ranked_efforts_count
    filtered_ranked_efforts.total_entries
  end

  def efforts_count
    event_group_efforts.size
  end

  def started_efforts
    @started_efforts ||= filtered_ranked_efforts.select(&:started?)
  end

  def unstarted_efforts
    @unstarted_efforts ||= filtered_ranked_efforts.reject(&:started?)
  end

  def ready_efforts
    @ready_efforts ||= event_group_efforts.ready_to_start
  end

  def ready_efforts_count
    ready_efforts.size
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

  def display_style
    params[:display_style]
  end

  def checked_in_filter?
    params[:checked_in]&.to_boolean
  end

  def started_filter?
    params[:started]&.to_boolean
  end

  def unreconciled_filter?
    params[:unreconciled]&.to_boolean
  end

  def event_group_efforts
    event_group.efforts.includes(:event)
  end

  def check_in_button_param
    :check_in_group
  end

  def method_missing(method)
    event_group.send(method)
  end

  private

  attr_reader :params, :current_user

  def filtered_ids
    @filtered_ids ||= event_group_efforts.where(filter_hash).search(search_text).ids.to_set
  end

  def matches_criteria?(effort)
    matches_checked_in_criteria?(effort) && matches_start_criteria?(effort) && matches_unreconciled_criteria?(effort)
  end

  def matches_checked_in_criteria?(effort)
    case checked_in_filter?
    when true
      effort.checked_in
    when false
      !effort.checked_in
    else # value is nil so do not filter
      true
    end
  end

  def matches_start_criteria?(effort)
    case started_filter?
    when true
      effort.started?
    when false
      !effort.started?
    else # value is nil so do not filter
      true
    end
  end

  def matches_unreconciled_criteria?(effort)
    case unreconciled_filter?
    when true
      effort.unreconciled?
    when false
      !effort.unreconciled?
    else # value is nil so do not filter
      true
    end
  end

  def scoped_efforts
    display_style == 'problems' ? event_group_efforts.invalid_status : event_group_efforts
  end
end
