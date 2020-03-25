# frozen_string_literal: true

class EffortPlaceView < EffortWithLapSplitRows
  delegate :simple?, :multiple_sub_splits?, :event_group, to: :event

  TimePointWithEffortInfo = Struct.new(:time_point, :rank, :ids_ahead)
  CategorizedEffortIds = Struct.new(:passed_segment, :passed_in_aid, :passed_by_segment, :passed_by_in_aid, :together_in_aid, keyword_init: true)

  def initialize(args_effort)
    @effort = args_effort.enriched
    set_time_point_ranks
  end

  def place_detail_rows
    @place_detail_rows ||=
      begin
        prior_time_point = lap_splits.first.time_point_in

        lap_splits.each_with_object([]) do |lap_split, rows|
          next if lap_split.start?

          previous_lap_split = lap_splits.find { |ls| ls.key == prior_time_point.lap_split_key }
          effort_ids_by_category = categorized_effort_ids(lap_split, prior_time_point)

          place_detail_row = PlaceDetailRow.new(effort_name: effort.name,
                                                lap_split: lap_split,
                                                previous_lap_split: previous_lap_split,
                                                split_times: related_split_times(lap_split),
                                                effort_ids_by_category: effort_ids_by_category,
                                                show_laps: event.multiple_laps?)
          rows << place_detail_row

          prior_time_point = place_detail_row.end_time_point if place_detail_row.end_time_point
        end
      end
  end

  def event
    @event ||= Event.where(id: effort.event_id).includes(:splits).first
  end

  def peers
    @peers ||= Effort.select(:id, :first_name, :last_name, :slug)
                 .where(id: frequent_encountered_ids)
                 .index_by(&:id)
                 .values_at(*frequent_encountered_ids)
  end

  private

  def categorized_effort_ids(lap_split, prior_time_point)
    CategorizedEffortIds.new(passed_segment: effort_ids_passed(prior_time_point, lap_split.time_point_in),
                             passed_in_aid: effort_ids_passed(lap_split.time_point_in, lap_split.time_point_out),
                             passed_by_segment: effort_ids_passed_by(prior_time_point, lap_split.time_point_in),
                             passed_by_in_aid: effort_ids_passed_by(lap_split.time_point_in, lap_split.time_point_out),
                             together_in_aid: effort_ids_together_in_aid(lap_split))
  end

  def effort_ids_passed(begin_time_point, end_time_point)
    effort_ids_moved_ahead(begin_time_point, end_time_point)
  end

  def effort_ids_passed_by(begin_time_point, end_time_point)
    effort_ids_moved_ahead(end_time_point, begin_time_point)
  end

  def effort_ids_moved_ahead(time_point_1, time_point_2)
    # Return empty array if either time point is nil or the starting time point
    return [] if ([time_point_1, time_point_2] & [nil, time_points.first]).present?

    ids_ahead_1 = effort_info_by_time_point[time_point_1]&.ids_ahead || []
    ids_ahead_2 = effort_info_by_time_point[time_point_2]&.ids_ahead || []
    ids_ahead_1 - ids_ahead_2
  end

  def effort_ids_together_in_aid(lap_split)
    []
  end

  def frequent_encountered_ids
    @frequent_encountered_ids ||= place_detail_rows.flat_map(&:encountered_ids).compact
                                    .count_each.sort_by { |_, count| -count }.first(5).map(&:first)
  end

  def ordered_efforts_at_time_points
    query = EventQuery.ordered_efforts_at_time_points(event.id)
    result = ActiveRecord::Base.connection.execute(query).to_a
    result.map { |row| OrderedEffortsAtTimePoint.new(row) }
  end

  def effort_info_array
    ordered_efforts_at_time_points.map do |oeatp|
      effort_ids = oeatp.effort_ids
      TimePointWithEffortInfo.new(oeatp.time_point, effort_ids.index(effort.id) + 1, effort_ids.elements_before(effort.id))
    end
  end

  def effort_info_by_time_point
    @effort_info_by_time_point ||= effort_info_array.index_by(&:time_point)
  end

  def related_split_times(lap_split)
    lap_split.time_points.map { |tp| indexed_split_times[tp] }
  end

  def set_time_point_ranks
    ordered_split_times.each do |split_time|
      split_time.time_point_rank = effort_info_by_time_point[split_time.time_point].rank
    end
  end
end
