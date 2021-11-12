# frozen_string_literal: true

class EventGroupTrafficPresenter < BasePresenter
  include SplitAnalyzable, TimeFormats

  attr_reader :event_group, :band_width
  delegate :name, :organization, :events, :home_time_zone, :scheduled_start_time_local, :available_live,
           :multiple_events?, to: :event_group

  def initialize(event_group, params, band_width)
    @event_group = event_group
    @parameterized_split_name = params[:parameterized_split_name] || parameterized_split_names.first
    @band_width = band_width || 30.minutes
  end

  def interval_split_traffics
    @interval_split_traffics ||= ::IntervalSplitTraffic.execute_query(event_group: event_group, split_name: parameterized_split_name, band_width: band_width)
  end

  def table_title
    case
    when split.nil?
      "Unknown split."
    when interval_split_traffics.nil?
      "Too many rows to analyze. Use a lower frequency."
    when interval_split_traffics.empty?
      "No entrants have arrived at this aid station."
    else
      "Traffic at #{split_name} in increments of #{band_width / 1.minute} minutes"
    end
  end

  def events_to_show
    @events_to_show ||=
      begin
        result = [overall_dummy_event]
        result += events if events.many?
        result
      end
  end

  # Represents the overall counts for the event group
  def overall_dummy_event
    ::Event.new(id: nil, short_name: "Overall")
  end

  def counts_header_string
    sub_split_kinds.many? ? sub_split_kinds.map { |kind| kind.to_s.titleize }.join(" / ") : 'Count'
  end

  def range_string(ist)
    "#{localized_time(ist.start_time)} to #{localized_time(ist.end_time)}"
  end

  def sub_split_counts_for_event(row, event_id)
    sub_split_kinds.map { |kind| row_counts(row, event_id, kind) }.join(" / ")
  end

  def sub_split_kinds
    @sub_split_kinds ||= split ? split.sub_split_kinds.map { |kind| kind.downcase.to_sym } : []
  end

  def event
    event_group.first_event
  end

  def overall_totals(event_id)
    sub_split_kinds.map { |kind| interval_split_traffics.sum { |row| row_counts(row, event_id, kind) } }.join(" / ")
  end

  def suggested_band_widths
    [1.minute, 2.minutes, 5.minutes, 10.minutes, 15.minutes, 30.minutes, 60.minutes]
  end

  private

  attr_reader :parameterized_split_name

  def row_counts(row, event_id, kind)
    row.counts_by_event[event_id].send(kind)
  end

  def split
    @split ||= Split.where(course_id: events.map(&:course_id)).find_by(parameterized_base_name: parameterized_split_name)
  end

  def indexed_events
    @indexed_events ||= events.index_by(&:id)
  end

  def localized_time(datetime)
    I18n.localize(datetime.in_time_zone(event_group.home_time_zone), format: :day_and_military)
  end
end
