# frozen_string_literal: true

class EventSeriesPresenter < BasePresenter

  def initialize(events, params)
    @events = events || []
    @params = params
  end

  def organization
    events.first&.organization
  end

  def organization_name
    organization&.name
  end

  def event_names
    events.map(&:name)
  end

  def series_efforts
    @series_efforts ||= common_efforts.map { |common_effort| build_series_effort(common_effort) }
                            .sort_by { |series_effort| series_effort.total_time }
  end

  private

  attr_reader :events, :params

  def common_efforts
    @common_efforts ||= Results::FindCommonEfforts.perform(events)
  end

  def build_series_effort(common_effort)
    Results::SeriesEffort.new(person: indexed_people[common_effort[:person_id]], efforts: common_effort[:efforts])
  end

  def indexed_people
    @indexed_people ||= Person.find(person_ids).index_by(&:id)
  end

  def person_ids
    common_efforts.map { |common_effort| common_effort[:person_id] }
  end
end
