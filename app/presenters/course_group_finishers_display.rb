# frozen_string_literal: true

class CourseGroupFinishersDisplay < BasePresenter
  DEFAULT_PER_PAGE = 50
  FIRST_PAGE = 1

  attr_reader :course_group, :view_context, :request

  delegate :name, :organization, :to_param, to: :course_group

  def initialize(course_group, view_context)
    @course_group = course_group
    @view_context = view_context
    @request = view_context.request
    @params = view_context.prepared_params
    @current_user = view_context.current_user
  end

  def filtered_finishers
    @filtered_finishers ||= filtered_finishers_unpaginated
                              .paginate(page: page, per_page: per_page, total_entries: 0)
                              .to_a
  end

  def filtered_finishers_unpaginated
    all_finishers.where(filter_hash).search(search_text)
                 .order(:finish_count, :last_name)
  end

  def filtered_finishers_count
    @filtered_finishers_count ||= filtered_finishers.size
  end

  def all_finishers_count
    @all_finishers_count ||= all_finishers.count
  end

  def events_count
    @events_count ||= events.size
  end

  def earliest_event_date
    events.last.scheduled_start_time.to_date.to_formatted_s(:long)
  end

  def most_recent_event_date
    most_recent_event && most_recent_event.scheduled_start_time.to_date.to_formatted_s(:long)
  end

  def most_recent_event
    events.select { |event| event.scheduled_start_time < Time.now }.max_by(&:scheduled_start_time)
  end

  def next_page_url
    view_context.url_for(request.params.merge(page: page + 1)) if filtered_finishers_count == per_page
  end

  def page
    params[:page]&.to_i || FIRST_PAGE
  end

  def per_page
    params[:per_page]&.to_i || DEFAULT_PER_PAGE
  end

  private

  attr_reader :params, :current_user

  def events
    @events ||=
      begin
        subquery = course_group.events.select("distinct on (events.id) events.id, events.event_group_id, events.course_id, events.scheduled_start_time").joins(:efforts)
        ::EventPolicy::Scope.new(current_user, ::Event.from(subquery, :events)).viewable.order(scheduled_start_time: :desc).to_a
      end
  end

  def all_finishers
    ::CourseGroupFinisher.for_course_groups(course_group)
  end
end
