# frozen_string_literal: true

class AidStationTimesPresenter < BasePresenter
  delegate :event_name, :split_name, to: :aid_station
  delegate :home_time_zone, :available_live, :podium_template, :event_group, :ordered_events_within_group, to: :event
  delegate :sub_split_kinds, to: :split

  def initialize(aid_station, params, current_user)
    @aid_station = aid_station
    @params = params
    @current_user = current_user
  end

  def bib_rows
    bib_numbers.map { |bib_number| bib_row(bib_number) }
  end

  def sources
    @sources ||= all_live_times.map(&:source_text).uniq.sort
  end

  def split_text
    split.name(bitkey)
  end

  def sub_split_kind
    params[:sub_split_kind] || 'In'
  end

  def prior_aid_station
    ordered_aid_stations.elements_before(aid_station)&.last
  end

  def next_aid_station
    ordered_aid_stations.elements_after(aid_station)&.first
  end

  def event_group_aid_stations
    EventGroupSplitAnalyzer.new(event_group).aid_stations_by_event(split_name)
  end

  private

  attr_reader :aid_station, :params, :current_user
  delegate :event, :split, to: :aid_station
  delegate :ordered_aid_stations, to: :event

  def bib_row(bib_number)
    BibSubSplitTimeRow.new(bib_number: bib_number,
                           effort: indexed_efforts[bib_number],
                           live_times: grouped_live_times[bib_number],
                           split_times: find_split_times(bib_number),
                           event: event)
  end

  def find_split_times(bib_number)
    effort = indexed_efforts[bib_number]
    grouped_split_times.fetch(effort&.id, [])
  end

  def all_live_times
    LiveTime.where(event: event, split: split)
  end

  def live_times
    all_live_times.where(bitkey: bitkey)
  end

  def bib_numbers
    @bib_numbers ||= grouped_live_times.keys.sort_by(&:to_i)
  end

  def indexed_efforts
    @indexed_efforts = event.efforts.index_by { |effort| effort.bib_number.to_s }
  end

  def grouped_split_times
    @indexed_split_times ||= event.split_times.includes(effort: :event).where(split: split, bitkey: bitkey).group_by(&:effort_id)
  end

  def grouped_live_times
    @indexed_live_times ||= live_times.group_by(&:bib_number)
  end

  def bitkey
    SubSplit.bitkey(sub_split_kind)
  end
end
