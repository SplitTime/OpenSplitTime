class EffortPlaceView < EffortWithLapSplitRows
  attr_reader :effort
  delegate :simple?, :multiple_sub_splits?, :event_group, to: :event

  def initialize(args_effort)
    @effort = args_effort.enriched
  end

  def place_detail_rows
    ordered_efforts_at_time_points
  end

  def event
    @event ||= Event.where(id: effort.event_id).eager_load(:splits, :efforts).first
  end

  def efforts_passed(begin_time_point, end_time_point)
    efforts_moved_ahead(begin_time_point, end_time_point)
  end

  def efforts_passed_by(begin_time_point, end_time_point)
    efforts_moved_ahead(end_time_point, begin_time_point)
  end

  def efforts_together_in_aid(lap_split)

  end

  def peers
    @peers ||= efforts_from_ids(frequent_encountered_ids)
  end

  private

  #who knows. Into the unknown!

  def ordered_efforts_at_time_points
    query = EventQuery.ordered_efforts_at_time_points(event.id)
    result = ActiveRecord::Base.connection.execute(query).to_a
    result.map { |row| OrderedEffortsAtTimePoint.new(row) }
  end

  def efforts_moved_ahead(begin_time_point, end_time_point)

  end
end