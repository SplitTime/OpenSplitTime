# frozen_string_literal: true

class SplitRawTimesPresenter < BasePresenter
  attr_reader :event_group, :split_name
  delegate :name, :organization, :events, :home_time_zone, :available_live, :multiple_events?, to: :event_group
  delegate :podium_template, to: :event

  def initialize(event_group, split_name, params, current_user)
    @event_group = event_group
    @split_name = split_name.presence&.titleize || ordered_split_names.first
    @params = params
    @current_user = current_user
  end

  def bib_rows
    bib_numbers.map { |bib_number| bib_row(bib_number) }
  end

  def sources
    @sources ||= raw_times.map(&:source_text).uniq.sort
  end

  def sub_split_kind
    param_kind = (params[:sub_split_kind] || 'in').parameterize
    sub_split_kinds.include?(param_kind) ? param_kind : 'in'
  end

  def sub_split_kinds
    @sub_split_kinds ||= splits.flat_map(&:sub_split_kinds).map(&:parameterize).uniq
  end

  def event
    events.first
  end

  def ordered_split_names
    @ordered_split_names ||= event_group.ordered_split_names.map(&:titleize)
  end

  def parameterized_split_name
    @parameterized_split_name ||= split_name.parameterize
  end

  private

  attr_reader :params, :current_user

  def bib_row(bib_number)
    BibSubSplitTimeRow.new(bib_number: bib_number,
                           effort: indexed_efforts[bib_number],
                           time_records: grouped_raw_times[bib_number],
                           split_times: fetch_split_times(bib_number),
                           event: event_group)
  end

  def fetch_split_times(bib_number)
    effort_id = indexed_efforts[bib_number]&.id
    grouped_split_times.fetch(effort_id, [])
  end

  def all_raw_times
    RawTime.where(event_group: event_group, parameterized_split_name: parameterized_split_name)
  end

  def raw_times
    @raw_times ||= all_raw_times.where(bitkey: bitkey).with_relation_ids(sort: sort_hash)
  end

  def bib_numbers
    @bib_numbers ||= grouped_raw_times.keys.sort_by(&:to_i)
  end

  def indexed_efforts
    @indexed_efforts = event_group.efforts.index_by { |effort| effort.bib_number.to_s }
  end

  def grouped_split_times
    @grouped_split_times ||= event_group.split_times.includes(effort: :event).where(split: splits, bitkey: bitkey).group_by(&:effort_id)
  end

  def grouped_raw_times
    @grouped_raw_times ||= raw_times.group_by(&:bib_number)
  end

  def splits
    Split.joins(:events).where(events: {id: event_group.events}, parameterized_base_name: parameterized_split_name)
  end

  def bitkey
    @bitkey ||= SubSplit.bitkey(sub_split_kind)
  end
end
