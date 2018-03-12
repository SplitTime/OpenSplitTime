# frozen_string_literal: true

class PlaceDetailView

  attr_reader :effort, :place_detail_rows
  delegate :full_name, :event_name, :person, :bib_number, :finish_status, :gender,
           :overall_rank, :gender_rank, to: :effort

  def initialize(args_effort)
    @effort = args_effort.enriched || args_effort
    @place_detail_rows = []
    create_place_detail_rows
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
    begin_time_point = lap_split.time_point_in
    end_time_point = lap_split.time_point_out
    return [] unless begin_time_point && end_time_point
    segment_times = indexed_segment_times(begin_time_point, end_time_point)
    return [] unless segment_times[effort.id]
    subject_time_in = segment_times[effort.id][:in]
    subject_time_out = segment_times[effort.id][:out]
    return [] unless subject_time_in && subject_time_out
    other_efforts.select do |effort|
      times_overlap?(subject_time_in, subject_time_out, segment_times[effort.id][:in], segment_times[effort.id][:out])
    end
  end

  def peers
    @peers ||= efforts_from_ids(frequent_encountered_ids)
  end

  private

  attr_reader :split_place_columns

  def create_place_detail_rows
    prior_time_point = lap_splits.first.time_point_in
    lap_splits.each do |lap_split|
      next if lap_split.start?
      previous_lap_split = lap_splits.find { |ls| ls.key == prior_time_point.lap_split_key }
      efforts = {passed_segment: efforts_passed(prior_time_point, lap_split.time_point_in),
                 passed_in_aid: efforts_passed(lap_split.time_point_in, lap_split.time_point_out),
                 passed_by_segment: efforts_passed_by(prior_time_point, lap_split.time_point_in),
                 passed_by_in_aid: efforts_passed_by(lap_split.time_point_in, lap_split.time_point_out),
                 together_in_aid: efforts_together_in_aid(lap_split)}
      place_detail_row = PlaceDetailRow.new(effort_name: effort.name,
                                            lap_split: lap_split,
                                            previous_lap_split: previous_lap_split,
                                            split_times: related_split_times(lap_split),
                                            efforts: efforts,
                                            show_laps: event.multiple_laps?)
      place_detail_rows << place_detail_row
      prior_time_point = place_detail_row.end_time_point if place_detail_row.end_time_point
    end
  end

  def efforts_moved_ahead(begin_time_point, end_time_point)
    ids_ahead = effort_ids_ahead(begin_time_point)
    ids_behind = effort_ids_ahead(end_time_point)
    ids_passed = (ids_ahead && ids_behind) ? ids_ahead - ids_behind : []
    efforts_from_ids(ids_passed)
  end

  def effort_ids_ahead(time_point)
    rank = effort_rank(time_point)
    grouped_split_times[time_point].first(rank - 1).map(&:effort_id) if rank
  end

  def effort_rank(time_point)
    indexed_effort_split_times[time_point]&.time_point_rank
  end

  def indexed_segment_times(begin_time_point, end_time_point)
    result = {}
    return {} unless grouped_split_times[begin_time_point].present?
    begin_split_times = grouped_split_times[begin_time_point].index_by(&:effort_id)
    end_split_times = grouped_split_times[end_time_point].index_by(&:effort_id)
    event_efforts.each do |effort|
      day_and_time_begin = begin_split_times[effort.id]&.day_and_time
      day_and_time_end = end_split_times[effort.id]&.day_and_time
      result[effort.id] = {in: day_and_time_begin, out: day_and_time_end}
    end
    result
  end

  def times_overlap?(range_1_start, range_1_end, range_2_start, range_2_end)
    range_1_start && range_1_end && range_2_start && range_2_end &&
        (range_1_start <= range_2_end) && (range_1_end >= range_2_start)
  end

  def related_split_times(lap_split)
    lap_split.time_points
        .map { |time_point| (grouped_split_times[time_point] || []).find { |st| st.effort_id == effort.id } }
  end

  def frequent_encountered_ids
    place_detail_rows.flat_map(&:encountered_ids).compact
        .count_each.sort_by { |_, count| -count }.first(5).map(&:first)
  end

  def efforts_from_ids(effort_ids)
    effort_ids.map { |effort_id| indexed_efforts[effort_id] }
  end

  def indexed_efforts
    @indexed_efforts ||= event_efforts.index_by(&:id)
  end

  def other_efforts
    @other_efforts ||= event_efforts - [effort]
  end

  def event_efforts
    @event_efforts ||= event.efforts.to_a
  end

  def grouped_split_times
    return @grouped_split_times if defined?(@grouped_split_times)
    @grouped_split_times = event_split_times.group_by(&:time_point)
    @grouped_split_times.default = []
    @grouped_split_times
  end

  def event_split_times
    @event_split_times ||=
        event.split_times.with_time_point_rank(split_time_fields: 'effort_id, lap, split_id, sub_split_bitkey')
  end

  def indexed_effort_split_times
    @indexed_effort_split_times ||= effort_split_times.index_by(&:time_point)
  end

  def effort_split_times
    @effort_split_times ||= event_split_times.select { |st| st.effort_id == effort.id }
  end

  def lap_splits
    @lap_splits ||= event.required_lap_splits.presence || event.lap_splits_through(last_lap)
  end

  def last_lap
    effort_split_times.map(&:lap).max || 1
  end
end
