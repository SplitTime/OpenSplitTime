# frozen_string_literal: true

class EventGroupTrafficPresenter < BasePresenter
  include SplitAnalyzable, TimeFormats

  ROW_LIMIT = 500

  attr_reader :event_group, :band_width
  delegate :name, :organization, :events, :home_time_zone, :available_live, :multiple_events?, to: :event_group
  delegate :podium_template, to: :event

  def initialize(event_group, params, band_width)
    @event_group = event_group
    @parameterized_split_name = params[:parameterized_split_name] || parameterized_split_names.first
    @band_width = band_width || 30.minutes
  end

  def table
    @table ||= row_limit_exceeded? ? [] : query_result.map do |row|
      OpenStruct.new(range: "#{row['start_time']} to #{row['end_time']}",
                     count: OpenStruct.new(in: row['in_count'],
                                           out: row['out_count'],
                                           finished_in: row['finished_in_count'],
                                           finished_out: row['finished_out_count']))
    end
  end

  def table_title
    case
    when query_result.empty?
      "No entrants have arrived at this aid station."
    when row_limit_exceeded?
      "Too many rows to analyze. Use a lower frequency."
    else
      "Traffic at #{split_name} in increments of #{band_width / 1.minute} minutes"
    end
  end

  def sub_split_kinds
    @sub_split_kinds ||= split.sub_split_kinds.map { |kind| kind.downcase.to_sym }
  end

  def event
    events.first
  end

  def totals(kind)
    table.sum { |row| row.count[kind] }
  end

  def suggested_band_widths
    [1.minute, 2.minutes, 5.minutes, 10.minutes, 15.minutes, 30.minutes, 60.minutes]
  end

  private

  attr_reader :parameterized_split_name

  def query_result
    @query_result ||= SplitTimeQuery.split_traffic(event_group: event_group, split_name: parameterized_split_name, band_width: band_width)
  end

  def split
    @split ||= Split.where(course_id: events.map(&:course_id)).find_by(parameterized_base_name: parameterized_split_name)
  end

  def row_limit_exceeded?
    query_result.size > ROW_LIMIT
  end
end
