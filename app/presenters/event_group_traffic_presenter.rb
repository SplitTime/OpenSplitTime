# frozen_string_literal: true

class EventGroupTrafficPresenter < BasePresenter
  include TimeFormats

  attr_reader :event_group, :split_name, :band_width
  delegate :name, :organization, :events, :home_time_zone, :available_live, :multiple_events?, to: :event_group
  delegate :podium_template, to: :event

  def initialize(event_group, split_name, band_width)
    @event_group = event_group
    @split_name = split_name.presence&.titleize || ordered_split_names.first
    @band_width = band_width.presence || 30.minutes
  end

  def table
    @table ||= analysis.resources[:table].map do |row|
      OpenStruct.new(range: "#{day_time_format(row[:low_time])} to #{day_time_format(row[:low_time] + band_width)}",
                     count: OpenStruct.new(in: row[:count][:in], out: row[:count][:out]))
    end
  end

  def table_title
    analysis.message
  end

  def sub_split_kinds
    @sub_split_kinds ||= split.sub_split_kinds.map { |kind| kind.downcase.to_sym }
  end

  def ordered_split_names
    @ordered_split_names ||= event_group.ordered_split_names.map(&:titleize)
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

  def analysis
    AnalyzeTrafficFrequency.perform(event_group: event_group, split_name: split_name, band_width: band_width)
  end

  def parameterized_split_name
    split_name.parameterize
  end

  def split
    @split ||= Split.where(course_id: events.map(&:course_id)).find_by(parameterized_base_name: parameterized_split_name)
  end
end
