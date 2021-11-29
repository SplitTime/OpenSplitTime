# frozen_string_literal: true

class EffortPlaceView < EffortWithLapSplitRows
  delegate :simple?, :multiple_sub_splits?, :event_group, to: :event

  CategorizedEffortIds = Struct.new(:passed_segment, :passed_in_aid, :passed_by_segment, :passed_by_in_aid, :together_in_aid, keyword_init: true)

  def initialize(args_effort)
    @effort = args_effort.enriched
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
                                                split_times: related_split_times(lap_split.time_points),
                                                effort_ids_by_category: effort_ids_by_category,
                                                show_laps: event.multiple_laps?)
          rows << place_detail_row

          prior_time_point = place_detail_row.end_time_point if place_detail_row.end_time_point
        end
      end
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
    return [] if split_time_missing_rank?(time_point_1, time_point_2)

    ids_ahead_1 = indexed_split_times[time_point_1].effort_ids_ahead
    ids_ahead_2 = indexed_split_times[time_point_2].effort_ids_ahead
    ids_ahead_1 - ids_ahead_2
  end

  def split_time_missing_rank?(*time_points)
    related_split_times(time_points).any? { |st| st&.time_point_rank.nil? }
  end

  def effort_ids_together_in_aid(lap_split)
    efforts_together_in_aid.find { |etia| etia.lap_split_key == lap_split.key }&.together_effort_ids || []
  end

  def efforts_together_in_aid
    @efforts_together_in_aid ||= EffortsTogetherInAid.execute_query(effort.id)
  end

  def frequent_encountered_ids
    @frequent_encountered_ids ||= place_detail_rows.flat_map(&:encountered_ids).compact
                                    .count_each.sort_by { |_, count| -count }.first(5).map(&:first)
  end

  def related_split_times(time_points)
    indexed_split_times.values_at(*time_points)
  end

  def ordered_split_times
    @ordered_split_times ||= effort.split_times.with_time_point_rank.to_a
  end
end
