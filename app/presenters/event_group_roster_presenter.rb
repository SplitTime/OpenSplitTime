# frozen_string_literal: true

class EventGroupRosterPresenter < BasePresenter
  attr_reader :event_group
  delegate :to_param, to: :event_group

  def initialize(event_group, params, current_user)
    @event_group = event_group
    @params = params
    @current_user = current_user
  end

  def started_efforts
    @started_efforts ||= roster_efforts.select(&:started?)
  end

  def unstarted_efforts
    @unstarted_efforts ||= roster_efforts.reject(&:started?)
  end

  def ready_efforts
    @ready_efforts ||= roster_efforts.select(&:ready_to_start)
  end

  def ready_efforts_count
    ready_efforts.size
  end

  def roster_efforts
    @roster_efforts ||= event_group_efforts.roster_subquery
  end

  def roster_efforts_count
    @roster_efforts_count ||= roster_efforts.size
  end

  def filtered_roster_efforts
    @filtered_roster_efforts ||= event_group_efforts
                                   .from(roster_efforts, "efforts")
                                   .where(filter_hash)
                                   .search(search_text)
                                   .order(sort_hash.presence || {bib_number: :asc})
                                   .select { |effort| matches_criteria?(effort) }
                                   .paginate(page: page, per_page: per_page)
  end

  def filtered_roster_efforts_count
    @filtered_roster_efforts_count ||= filtered_roster_efforts.size
  end

  def events
    @events ||= event_group.events.select_with_params('').order(:scheduled_start_time).to_a
  end

  def event
    events.first
  end

  def display_style
    nil
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

  def matches_criteria?(effort)
    matches_checked_in_criteria?(effort) && matches_start_criteria?(effort) && matches_unreconciled_criteria?(effort) && matches_problem_criteria?(effort)
  end

  def matches_checked_in_criteria?(effort)
    case params[:checked_in]&.to_boolean
    when true
      effort.checked_in
    when false
      !effort.checked_in
    else # value is nil so do not filter
      true
    end
  end

  def matches_start_criteria?(effort)
    case params[:started]&.to_boolean
    when true
      effort.started?
    when false
      !effort.started?
    else # value is nil so do not filter
      true
    end
  end

  def matches_unreconciled_criteria?(effort)
    case params[:unreconciled]&.to_boolean
    when true
      effort.unreconciled?
    when false
      !effort.unreconciled?
    else # value is nil so do not filter
      true
    end
  end

  def matches_problem_criteria?(effort)
    case params[:problem]&.to_boolean
    when true
      !effort.valid_status?
    when false
      effort.valid_status?
    else # value is nil so do not filter
      true
    end
  end
end
