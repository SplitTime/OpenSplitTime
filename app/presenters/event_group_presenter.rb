# frozen_string_literal: true

class EventGroupPresenter < BasePresenter
  attr_reader :event_group
  delegate :to_param, to: :event_group

  CANDIDATE_SEPARATION_LIMIT = 7.days
  DEFAULT_DISPLAY_STYLE = 'events'
  RECENT_FINISH_THRESHOLD = 20.minutes
  RECENT_FINISH_COUNT_LIMIT = 6
  EXPECTED_FINISH_COUNT_LIMIT = 10

  def initialize(event_group, params, current_user)
    @event_group = event_group
    @params = params
    @current_user = current_user
  end

  def ranked_efforts
    return @ranked_efforts if defined?(@ranked_efforts)

    @ranked_efforts = event_group_efforts.ranked_with_status(sort: sort_hash.presence || {bib_number: :asc})
    @ranked_efforts.each { |effort| effort.event = indexed_events[effort.event_id] }
    @ranked_efforts
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
    ranked_efforts.size
  end

  def dropped_effort_rows
    @dropped_effort_rows ||= ranked_efforts.select(&:dropped?).map { |effort| EffortRow.new(effort) }
  end

  def dropped_efforts_count
    dropped_effort_rows.size
  end

  def projected_arrivals_at_finish
    @projected_arrivals_at_finish ||=
      begin
        finish_split_name = event.ordered_splits.last.parameterized_base_name
        ::ProjectedArrivalsAtSplit.execute_query(event_group.id, finish_split_name)
      end
  end

  def expected_arrivals_at_finish
    projected_arrivals_at_finish.select(&:expected?).reverse.first(EXPECTED_FINISH_COUNT_LIMIT)
  end

  def recent_arrivals_at_finish
    projected_arrivals_at_finish
      .select { |arrival| arrival.completed? && arrival.projected_time.present? && arrival.projected_time > RECENT_FINISH_THRESHOLD.ago }
      .first(RECENT_FINISH_COUNT_LIMIT)
  end

  def events
    @events ||= event_group.events.select_with_params('').order(:scheduled_start_time).to_a
  end

  def event_group_names
    events.map(&:name).to_sentence(two_words_connector: ' and ', last_word_connector: ', and ')
  end

  def event
    events.first
  end

  def candidate_events
    (organization.events.select_with_params('').order(scheduled_start_time: :desc) - events)
        .select { |event| (event.scheduled_start_time - events.first.scheduled_start_time).abs < CANDIDATE_SEPARATION_LIMIT }
  end

  def show_visibility_columns?
    current_user&.authorized_to_edit?(event_group)
  end

  def display_style
    params[:display_style] || DEFAULT_DISPLAY_STYLE
  end

  def event_group_efforts
    event_group.efforts.includes(:event)
  end

  def method_missing(method)
    event_group.send(method)
  end

  private

  attr_reader :params, :current_user

  def filtered_ids
    @filtered_ids ||= event_group_efforts.where(filter_hash).search(search_text).ids.to_set
  end

  def indexed_events
    @indexed_events = events.index_by(&:id)
  end
end
