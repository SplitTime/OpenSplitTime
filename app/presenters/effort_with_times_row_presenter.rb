# frozen_string_literal: true

class EffortWithTimesRowPresenter < EffortWithLapSplitRows
  include ActiveModel::Serialization

  delegate :id, :event, :event_name, :split_times, :to_param, to: :effort

  def post_initialize(effort, args)
    ArgsValidator.validate(subject: effort, params: args, class: self.class)
    @effort = effort
  end

  def effort_times_row
    @effort_times_row ||= EffortTimesRow.new(effort: effort,
                                             lap_splits: lap_splits,
                                             split_times: split_times,
                                             display_style: 'all')
  end

  def event_split_header_data
    event_presenter.split_header_data.first(time_cluster_count)
  end

  def event_short_name
    event.guaranteed_short_name
  end

  private

  attr_reader :params

  def time_cluster_count
    effort_times_row.time_clusters.size
  end

  def event_presenter
    @event_presenter ||= EventSpreadDisplay.new(event: event, params: {display_style: 'all'})
  end
end
