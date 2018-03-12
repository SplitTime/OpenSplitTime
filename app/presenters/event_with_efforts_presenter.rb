# frozen_string_literal: true

class EventWithEffortsPresenter < BasePresenter

  attr_reader :event
  delegate :id, :name, :course, :simple?, :beacon_url, :home_time_zone, :finish_split,
           :start_split, :multiple_laps?, :to_param, :created_by, :new_record?, :event_group,
           :ordered_events_within_group, :podium_template, to: :event
  delegate :available_live, :available_live?, :concealed, :concealed?, :organization, to: :event_group

  def initialize(args)
    @event = args[:event]
    @params = args[:params] || {}
    post_initialize(args)
  end

  def post_initialize(args)
    ArgsValidator.validate(params: args, required: [:event, :params], exclusive: [:event, :params], class: self.class)
  end

  def ranked_effort_rows
    @ranked_effort_rows ||= filtered_ranked_efforts.map do |effort|
      person = indexed_people[effort.person_id]
      effort.person = person if person
      EffortRow.new(effort)
    end
  end

  def filtered_ranked_efforts
    @filtered_ranked_efforts ||=
        ranked_efforts
            .select { |effort| filtered_ids.include?(effort.id) }
            .paginate(page: page, per_page: per_page)
  end

  def event_efforts
    event.efforts
  end

  def efforts_count
    event_efforts.size
  end

  def started_efforts_count
    started_effort_ids.size
  end

  def unstarted_efforts_count
    efforts_count - started_efforts_count
  end

  def filtered_ranked_efforts_count
    filtered_ranked_efforts.total_entries
  end

  def course_name
    course.name
  end

  def organization_name
    organization&.name
  end

  def event_finished?
    event.finished?
  end

  def event_start_time
    @event_start_time ||= event.start_time_in_home_zone
  end

  def existing_sort
    params.original_params[:sort]
  end

  private

  attr_reader :params

  def ranked_efforts
    @ranked_efforts ||= event_efforts.ranked_with_finish_status(sort: sort_hash)
  end

  def unstarted_efforts
    @unstarted_efforts ||= event_efforts.where(id: unstarted_effort_ids).eager_load(:person)
  end

  def unstarted_effort_ids
    @unstarted_effort_ids ||= event_efforts.ids - started_effort_ids
  end

  def started_effort_ids
    @started_effort_ids ||= ranked_efforts.map(&:id)
  end

  def filtered_ids
    @filtered_ids ||= event_efforts.where(filter_hash).search(search_text).ids.to_set
  end

  def indexed_people
    @indexed_people ||= Person.where(id: person_ids).index_by(&:id)
  end

  def person_ids
    @person_ids ||= (filtered_ranked_efforts.map(&:person_id) + filtered_unstarted_efforts.map(&:person_id)).compact
  end
end
