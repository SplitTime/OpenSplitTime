class CourseGroupBestEffortsDisplay < BasePresenter
  include ActionView::Helpers::TextHelper

  attr_reader :course_group, :view_context, :request

  delegate :name, :organization, :to_param, to: :course_group

  def initialize(course_group, view_context)
    @course_group = course_group
    @view_context = view_context
    @request = view_context.request
    @params = view_context.prepared_params
  end

  def filtered_segments
    @filtered_segments ||= filtered_segments_unpaginated
                             .paginate(page: page, per_page: per_page, total_entries: 0)
                             .to_a
  end

  def filtered_segments_unpaginated
    ::BestEffortSegment.from(ranked_segments, :best_effort_segments)
      .where(effort: filtered_efforts)
      .order(:overall_rank)
  end

  def filtered_segments_count
    @filtered_segments_count ||= filtered_segments.size
  end

  def all_efforts_count
    @all_efforts_count ||= all_efforts.count
  end

  def events_count
    @events_count ||= events.size
  end

  def events_searched_text
    date_text = if events_count == 1
                  "on #{earliest_event_date}"
                else
                  "from #{[earliest_event_date, most_recent_event_date].compact.join(' to ')}"
                end

    "Searched #{pluralize(events_count, 'event')} #{date_text}"
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

  def relevant_genders
    all_efforts.distinct.pluck(:gender)
  end

  def time_header_text
    "Course Time"
  end

  def next_page_url
    view_context.url_for(request.params.merge(page: page + 1)) if filtered_segments_count == per_page
  end

  private

  attr_reader :params

  def events
    @events ||= course_group.events
                  .includes(:event_group)
                  .order(scheduled_start_time: :desc)
                  .select(&:visible?)
  end

  def all_efforts
    ::Effort.where(event: events).finished
  end

  def filtered_efforts
    all_efforts.where(filter_hash).search(search_text)
  end

  def all_segments
    ::BestEffortSegment.for_courses(course_group.courses).full_course
  end

  def ranked_segments
    ::BestEffortSegment.from(all_segments, :best_effort_segments)
      .with_overall_gender_age_and_event_rank
  end
end
