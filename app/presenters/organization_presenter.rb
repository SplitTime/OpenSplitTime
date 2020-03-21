# frozen_string_literal: true

class OrganizationPresenter < BasePresenter
  attr_reader :organization
  delegate :id, :name, :description, :stewards, :event_series, :to_param, to: :organization

  def initialize(organization, params, current_user)
    @organization = organization
    @params = params
    @current_user = current_user
  end

  def event_groups
    scoped_event_groups = EventGroupPolicy::Scope.new(current_user, EventGroup).viewable.search(params[:search])
    EventGroup.distinct
        .joins(:events) # Excludes "orphaned" event_groups (having no events)
        .where(id: scoped_event_groups.map(&:id), organization: organization)
        .includes(events: :efforts).includes(:organization)
        .sort_by { |event_group| -event_group.start_time.to_i }
  end

  def event_series
    organization.event_series.includes(events: :event_group).sort_by(&:start_time).reverse
  end

  def event_date_range(series)
    dates = event_dates(series)
    [dates.first, dates.last].uniq.join(' to ')
  end

  def courses
    scoped_courses = CoursePolicy::Scope.new(current_user, Course).viewable
    @courses ||= organization.courses.includes(:splits, :events).where(id: scoped_courses)
  end

  def display_style
    %w[courses stewards events event_series].include?(params[:display_style]) ? params[:display_style] : default_display_style
  end

  def default_display_style
    'events'
  end

  def show_visibility_columns?
    current_user&.authorized_to_edit?(organization)
  end

  private

  attr_reader :params, :current_user

  def event_dates(series)
    series.events.map(&:start_time).sort.map { |datetime| I18n.localize(datetime, format: :date_only) }
  end
end
