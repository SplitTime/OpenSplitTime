# frozen_string_literal: true

class EventGroupSetupPresenter < BasePresenter
  attr_reader :event_group
  delegate :events, :partners, :organization, :to_param, to: :event_group

  def initialize(event_group, params, current_user)
    @event_group = event_group
    @params = params
    @current_user = current_user
  end

  def available_courses
    organization.courses
  end

  def display_style
    params[:display_style].presence || default_display_style
  end

  def event_group_name
    event_group.name
  end

  def organization_name
    organization.name
  end

  private

  attr_reader :params

  def default_display_style
    "events"
  end
end
