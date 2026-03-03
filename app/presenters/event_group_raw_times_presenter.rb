class EventGroupRawTimesPresenter < BasePresenter
  include PagyPresenter

  attr_reader :event_group, :request, :pagy

  delegate :to_param, to: :event_group

  def initialize(event_group, view_context)
    @event_group = event_group
    @view_context = view_context
    @request = view_context.request
    @params = view_context.prepared_params
  end

  def events
    @events ||= event_group.events.sort_by(&:scheduled_start_time)
  end

  def event_group_names
    events.map(&:name).to_sentence(two_words_connector: " and ", last_word_connector: ", and ")
  end

  def event
    events.first
  end

  def raw_times
    event_group.raw_times
  end

  def raw_times_count
    raw_times.size
  end

  def filtered_raw_times
    return @filtered_raw_times if defined?(@filtered_raw_times)

    relation = raw_times.where(filter_hash).search(search_text)

    relation = apply_stopped_filter(relation)
    relation = apply_reviewed_filter(relation)
    relation = apply_matched_filter(relation)

    @pagy, @filtered_raw_times = pagy_from_scope(
      relation.with_relation_ids(sort: sort_hash),
      items: per_page,
      page: page
    )
    
    # Preload associations for the paginated subset to avoid N+1 queries
    ActiveRecord::Associations::Preloader.new(
      records: @filtered_raw_times,
      associations: [:creator, :reviewer]
    ).call
    
    @filtered_raw_times.each do |raw_time|
      raw_time.effort = raw_time.has_effort_id? ? indexed_efforts[raw_time.effort_id] : nil
      raw_time.event = raw_time.has_event_id? ? indexed_events[raw_time.event_id] : nil
      raw_time.split = raw_time.has_split_id? ? indexed_splits[raw_time.split_id] : nil
    end
    
    @filtered_raw_times
  end

  def filtered_raw_times_count
    filtered_raw_times.size
  end

  def filtered_raw_times_unpaginated_count
    pagy.count
  end

  def next_page_url
    view_context.url_for(request.params.merge(page: pagy.next)) if pagy.next
  end

  def split_name
    params.filter[:parameterized_split_name] || "All Splits"
  end

  def method_missing(method)
    event_group.send(method)
  end

  private

  attr_reader :view_context, :params

  def indexed_efforts
    @indexed_efforts ||= event_group.efforts.index_by(&:id)
  end

  def indexed_events
    @indexed_events ||= event_group.events.index_by(&:id)
  end

  def indexed_splits
    @indexed_splits ||= event_group.events.flat_map(&:splits).uniq.index_by(&:id)
  end

  def apply_stopped_filter(relation)
    case params[:stopped]&.to_boolean
    when true
      relation.where(stopped_here: true)
    when false
      relation.where(stopped_here: [false, nil])
    else
      relation
    end
  end

  def apply_reviewed_filter(relation)
    case params[:reviewed]&.to_boolean
    when true
      relation.where.not(reviewed_by: nil)
    when false
      relation.where(reviewed_by: nil)
    else
      relation
    end
  end

  def apply_matched_filter(relation)
    case params[:matched]&.to_boolean
    when true
      relation.where.not(split_time_id: nil)
    when false
      relation.where(split_time_id: nil)
    else
      relation
    end
  end
end
