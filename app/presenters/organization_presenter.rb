# frozen_string_literal: true

class OrganizationPresenter < BasePresenter
  attr_reader :organization

  delegate :id, :name, :description, :stewards, :event_series, :to_param, to: :organization
  delegate :controller_name, to: :view_context

  def initialize(organization, view_context)
    @organization = organization
    @view_context = view_context
    @params = view_context.prepared_params
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

  def tab_name
    controller_name == "organizations" ? "events" : controller_name
  end

  def event_date_range(series)
    dates = event_dates(series)
    [dates.first, dates.last].uniq.join(" to ")
  end

  def courses
    scoped_courses = CoursePolicy::Scope.new(current_user, Course).viewable
    @courses ||= organization.courses.includes(:splits, :events).where(id: scoped_courses).order(:name)
  end

  def course_groups
    @course_groups ||= ::CourseGroupPolicy::Scope.new(current_user, organization.course_groups).viewable
  end

  def show_visibility_columns?
    current_user&.authorized_to_edit?(organization)
  end

  private

  attr_reader :view_context, :params
  delegate :current_user, to: :view_context, private: true

  def event_groups
    organization.event_groups.by_group_start_time.includes(:events)
  end

  def event_dates(series)
    series.events.map(&:scheduled_start_time).sort.map { |datetime| I18n.localize(datetime, format: :date_only) }
  end
end
