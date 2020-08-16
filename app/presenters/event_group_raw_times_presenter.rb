# frozen_string_literal: true

class EventGroupRawTimesPresenter < BasePresenter
  attr_reader :event_group
  delegate :to_param, to: :event_group

  def initialize(event_group, params, current_user)
    @event_group = event_group
    @params = params
    @current_user = current_user
  end

  def events
    @events ||= event_group.events.sort_by(&:scheduled_start_time)
  end

  def event_group_names
    events.map(&:name).to_sentence(two_words_connector: ' and ', last_word_connector: ', and ')
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
    @filtered_raw_times = raw_times.where(filter_hash).search(search_text)
                              .with_relation_ids(sort: sort_hash)
                              .select { |raw_time| matches_criteria?(raw_time) }
                              .paginate(page: page, per_page: per_page)
    @filtered_raw_times.each do |raw_time|
      raw_time.effort = raw_time.has_effort_id? ? indexed_efforts[raw_time.effort_id] : nil
      raw_time.event = raw_time.has_event_id? ? indexed_events[raw_time.event_id] : nil
      raw_time.split = raw_time.has_split_id? ? indexed_splits[raw_time.split_id] : nil
      raw_time.creator = raw_time.created_by? ? indexed_users[raw_time.created_by] : nil
      raw_time.reviewer = raw_time.reviewed_by? ? indexed_users[raw_time.reviewed_by] : nil
    end
  end

  def filtered_raw_times_count
    filtered_raw_times.total_entries
  end

  def split_name
    params.filter[:parameterized_split_name] || 'All Splits'
  end

  def method_missing(method)
    event_group.send(method)
  end

  private

  attr_reader :params, :current_user

  def indexed_efforts
    @indexed_efforts ||= event_group.efforts.index_by(&:id)
  end

  def indexed_events
    @indexed_events ||= event_group.events.index_by(&:id)
  end

  def indexed_splits
    @indexed_splits ||= event_group.events.flat_map(&:splits).uniq.index_by(&:id)
  end

  def indexed_users
    @indexed_users ||= User.where(id: user_ids).index_by(&:id)
  end

  def user_ids
    @user_ids ||= filtered_raw_times.flat_map { |raw_time| [raw_time.created_by, raw_time.reviewed_by] }.compact.uniq
  end

  def matches_criteria?(raw_time)
    matches_stopped_criteria?(raw_time) && matches_reviewed_criteria?(raw_time) && matches_matched_criteria?(raw_time)
  end

  def matches_stopped_criteria?(raw_time)
    case params[:stopped]&.to_boolean
    when true
      raw_time.stopped_here
    when false
      !raw_time.stopped_here
    else # value is nil so do not filter
      true
    end
  end

  def matches_reviewed_criteria?(raw_time)
    case params[:reviewed]&.to_boolean
    when true
      raw_time.reviewed_by.present?
    when false
      raw_time.reviewed_by.blank?
    else # value is nil so do not filter
      true
    end
  end

  def matches_matched_criteria?(raw_time)
    case params[:matched]&.to_boolean
    when true
      raw_time.split_time_id.present?
    when false
      raw_time.split_time_id.blank?
    else # value is nil so do not filter
      true
    end
  end
end
