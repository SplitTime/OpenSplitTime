# frozen_string_literal: true

class EventGroupSetupPresenter < BasePresenter
  CANDIDATE_SEPARATION_LIMIT = 7.days

  attr_reader :event_group
  delegate :available_live?, :concealed?, :partners, :name, :organization, :to_param, to: :event_group

  def initialize(event_group, params, current_user)
    @event_group = event_group
    @params = params
    @current_user = current_user
  end

  def authorized_fully?
    @authorized_fully ||= current_user.authorized_fully?(event_group)
  end

  def available_courses
    organization.courses
  end

  def candidate_events
    return [] unless events.present?

    (organization.events.select_with_params("").order(scheduled_start_time: :desc) - events)
      .select { |event| (event.scheduled_start_time - events.first.scheduled_start_time).abs < CANDIDATE_SEPARATION_LIMIT }
  end

  def courses
    events.map(&:course).uniq
  end

  def display_style
    params[:display_style].presence || default_display_style
  end

  def event_group_name
    event_group.name
  end

  def events
    @events ||= event_group.events.order(:scheduled_start_time).to_a
  end

  def organization_name
    organization.name
  end

  def mode
    "setup"
  end

  private

  attr_reader :params, :current_user

  def default_display_style
    "events"
  end
end
