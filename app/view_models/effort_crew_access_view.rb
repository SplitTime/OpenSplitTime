class EffortCrewAccessView < EffortWithLapSplitRows
  delegate :event_name, to: :effort
  delegate :simple?, to: :event

  def gating_location_events
    @gating_location_events ||=
      event.gating_location_events
           .includes(:gating_location, gating_aid_station: :split, target_aid_station: :split, event: :splits)
           .sort_by { |gle| gle.gating_location.name }
  end

  def gating_rows
    return @gating_rows if defined?(@gating_rows)

    preload_effort_split_times
    @gating_rows = gating_location_events.map do |gating_location_event|
      GatingLocationRow.new(effort: effort, gating_location_event: gating_location_event)
    end
  end

  private

  def preload_effort_split_times
    ActiveRecord::Associations::Preloader.new(records: [effort], associations: { split_times: :split }).call
  end
end
