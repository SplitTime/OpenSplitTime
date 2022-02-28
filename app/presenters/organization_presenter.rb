# frozen_string_literal: true

class OrganizationPresenter < BasePresenter
  PERMITTED_DISPLAY_STYLES = %w[courses stewards events event_series lotteries].freeze

  attr_reader :organization

  delegate :id, :name, :description, :stewards, :event_series, :to_param, to: :organization

  def initialize(organization, params, current_user)
    @organization = organization
    @params = params
    @current_user = current_user
  end

  def lotteries
    scoped_lotteries = LotteryPolicy::Scope.new(current_user, Lottery).viewable
    scoped_lotteries.where(organization: organization).order(scheduled_start_date: :desc)
  end

  def concealed_event_groups
    event_groups.concealed
  end

  def visible_event_groups
    event_groups.visible
  end

  def event_series
    organization.event_series.includes(events: :event_group).sort_by(&:scheduled_start_time).reverse
  end

  def event_date_range(series)
    dates = event_dates(series)
    [dates.first, dates.last].uniq.join(" to ")
  end

  def courses
    scoped_courses = CoursePolicy::Scope.new(current_user, Course).viewable
    @courses ||= organization.courses.includes(:splits, :events).where(id: scoped_courses)
  end

  def display_style
    PERMITTED_DISPLAY_STYLES.include?(params[:display_style]) ? params[:display_style] : default_display_style
  end

  def default_display_style
    "events"
  end

  def show_visibility_columns?
    current_user&.authorized_to_edit?(organization)
  end

  private

  attr_reader :params, :current_user

  def event_groups
    organization.event_groups.by_group_start_time.includes(:events)
  end

  def event_dates(series)
    series.events.map(&:scheduled_start_time).sort.map { |datetime| I18n.localize(datetime, format: :date_only) }
  end
end
