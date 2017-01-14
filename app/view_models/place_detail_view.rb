class PlaceDetailView

  attr_reader :effort, :event, :place_detail_rows
  delegate :full_name, :event_name, :participant, :bib_number, :finish_status, :gender,
           :overall_place, :gender_place, to: :effort

  def initialize(args_effort)
    @effort = args_effort.enriched || args_effort
    @event = effort.event
    @event_efforts = event.efforts.to_a
    @indexed_start_offsets = Hash[event_efforts.map { |e| [e.id, e.start_offset] }]
    @ordered_splits = event.ordered_splits.to_a
    @event_split_times = event.split_times.to_a
    set_day_and_time_attrs
    @indexed_split_times = event_split_times.group_by(&:sub_split)
    @split_place_columns = {}
    create_split_place_columns
    @place_detail_rows = []
    create_place_detail_rows
  end

  def efforts_passed(begin_sub_split, end_sub_split)
    begin_ids_ahead = effort_ids_ahead(begin_sub_split)
    end_ids_ahead = effort_ids_ahead(end_sub_split)
    return [] unless begin_ids_ahead && end_ids_ahead
    ids_passed = begin_ids_ahead - end_ids_ahead
    event_efforts.select { |effort| ids_passed.include?(effort.id) }
  end

  def efforts_passed_by(begin_sub_split, end_sub_split)
    begin_ids_ahead = effort_ids_ahead_or_tied(begin_sub_split)
    end_ids_ahead = effort_ids_ahead(end_sub_split)
    return [] unless begin_ids_ahead && end_ids_ahead
    ids_passed_by = end_ids_ahead - begin_ids_ahead
    event_efforts.select { |effort| ids_passed_by.include?(effort.id) }
  end

  def efforts_together_in_aid(split)
    result = []
    begin_sub_split = split.sub_split_in
    end_sub_split = split.sub_split_out
    return [] unless begin_sub_split && end_sub_split
    segment_times = indexed_segment_times(begin_sub_split, end_sub_split)
    return [] unless segment_times[effort.id]
    subject_time_in = segment_times[effort.id][:in]
    subject_time_out = segment_times[effort.id][:out]
    return [] unless subject_time_in && subject_time_out
    event_efforts.each do |e|
      if times_overlap?(subject_time_in, subject_time_out, segment_times[e.id][:in], segment_times[e.id][:out])
        result << e
      end
    end
    result - [effort]
  end

  def peers
    indexed_efforts = event_efforts.index_by(&:id)
    frequent_encountered_ids.map { |effort_id| indexed_efforts[effort_id] }
  end

  private

  attr_reader :ordered_splits, :event_efforts, :event_split_times, :indexed_split_times,
              :indexed_start_offsets, :split_place_columns

  def set_day_and_time_attrs
    event_start_time = event.start_time
    event_split_times.each { |split_time| split_time.day_and_time_attr =
        event_start_time + split_time.time_from_start + indexed_start_offsets[split_time.effort_id] }
  end

  def create_split_place_columns

    # Each column element contains a hash with
    # {effort_id: effort.id, day_and_time: datetime}, sorted by day_and_time

    sub_splits = ordered_splits.map(&:sub_splits).flatten
    indexed_bib_numbers = Hash[event_efforts.map { |effort| [effort.id, effort.bib_number] }]
    sub_splits.each do |sub_split|
      split_times = indexed_split_times[sub_split]
      next unless split_times
      split_place_column = split_times.map { |split_time| {effort_id: split_time.effort_id,
                                                           day_and_time: split_time.day_and_time_attr,
                                                           bib_number: indexed_bib_numbers[split_time.effort_id]} }

      # Use bib_number for secondary sort to improve consistency when day_and_time are the same between efforts

      split_place_column.sort_by! { |row| [row[:day_and_time], row[:bib_number]] }
      split_place_columns[sub_split] = split_place_column
    end
  end

  def create_place_detail_rows
    prior_sub_split = ordered_splits.first.sub_split_in
    ordered_splits.each do |split|
      next if split.start?
      previous_split = ordered_splits.find { |s| s.id == prior_sub_split.split_id }
      efforts = {passed_segment: efforts_passed(prior_sub_split, split.sub_split_in),
                 passed_in_aid: efforts_passed(split.sub_split_in, split.sub_split_out),
                 passed_by_segment: efforts_passed_by(prior_sub_split, split.sub_split_in),
                 passed_by_in_aid: efforts_passed_by(split.sub_split_in, split.sub_split_out),
                 together_in_aid: efforts_together_in_aid(split)}
      place_detail_row = PlaceDetailRow.new(effort,
                                            split,
                                            previous_split,
                                            related_split_times(split),
                                            {split_place_in: split_place(split.sub_split_in),
                                             split_place_out: split_place(split.sub_split_out)},
                                            efforts)
      place_detail_rows << place_detail_row
      prior_sub_split = place_detail_row.end_sub_split if place_detail_row.end_sub_split
    end
  end

  def split_place(sub_split)
    return nil unless split_place_columns[sub_split]
    ordered_effort_ids = split_place_columns[sub_split].map { |row| row[:effort_id] }
    ordered_effort_ids.index(effort.id) ? ordered_effort_ids.index(effort.id) + 1 : nil
  end

  def effort_ids_tied(sub_split)
    return nil unless split_place_columns[sub_split]
    split_place_column = split_place_columns[sub_split]
    subject_row = split_place_column.find { |row| row[:effort_id] == effort.id }
    return nil unless subject_row.present?
    subject_time = subject_row[:day_and_time]
    tied_rows = split_place_column.select { |row| row[:day_and_time] == subject_time }
    tied_rows.map { |row| row[:effort_id] } - [effort.id]
  end

  def effort_ids_ahead(sub_split)
    return nil unless split_place_columns[sub_split]
    ordered_effort_ids = split_place_columns[sub_split].map { |row| row[:effort_id] }
    return [] if split_place(sub_split) == 1
    return nil unless ordered_effort_ids.include?(effort.id)
    ordered_effort_ids[0..(ordered_effort_ids.index(effort.id) - 1)] - effort_ids_tied(sub_split)
  end

  def effort_ids_ahead_or_tied(sub_split)
    ids_ahead = effort_ids_ahead(sub_split)
    ids_tied = effort_ids_tied(sub_split)
    return nil if ids_ahead.nil? && ids_tied.nil?
    (ids_ahead || []) + (ids_tied || [])
  end

  def indexed_segment_times(begin_sub_split, end_sub_split)
    result = {}
    return {} unless indexed_split_times[begin_sub_split]
    begin_split_times = indexed_split_times[begin_sub_split].index_by(&:effort_id)
    end_split_times = indexed_split_times[end_sub_split].index_by(&:effort_id)
    event_efforts.each do |effort|
      day_and_time_begin = begin_split_times[effort.id] ? begin_split_times[effort.id].day_and_time_attr : nil
      day_and_time_end = end_split_times[effort.id] ? end_split_times[effort.id].day_and_time_attr : nil
      result[effort.id] = {in: day_and_time_begin, out: day_and_time_end}
    end
    result
  end

  def times_overlap?(subject_time_start, subject_time_end, compare_time_start, compare_time_end)
    return false unless subject_time_start && subject_time_end && compare_time_start && compare_time_end
    (subject_time_start <= compare_time_end) && (subject_time_end >= compare_time_start)
  end

  def time_within?(subject_time_start, subject_time_end, compare_time)
    return false unless subject_time_start && subject_time_end && compare_time
    (subject_time_start <= compare_time) && (subject_time_end >= compare_time)
  end

  def related_split_times(split)
    split.sub_splits.collect { |key_hash| indexed_split_times[key_hash] ?
        indexed_split_times[key_hash].index_by(&:effort_id)[effort.id] : [] }
  end

  def frequent_encountered_ids
    encountered_ids = (place_detail_rows.map(&:together_in_aid_ids).flatten +
        place_detail_rows.map(&:passed_segment_ids).flatten +
        place_detail_rows.map(&:passed_by_segment_ids).flatten).compact
    counts = Hash.new(0)
    encountered_ids.each { |id| counts[id] += 1 }
    counts.sort_by { |_, count| count }.reverse.first(5).map { |e| e[0] }
  end
end