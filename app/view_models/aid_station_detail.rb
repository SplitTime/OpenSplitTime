class AidStationDetail < LiveEventFramework

  attr_reader :aid_station, :times_container
  delegate :course, :race, to: :event
  delegate :event, :split, :split_id, :open_time, :close_time, :status, :captain_name, :comms_crew_names,
           :comms_frequencies, :current_issues, to: :aid_station
  delegate :split_name, :category_sizes, :category_table_titles, to: :aid_station_row

  AID_EFFORT_CATEGORIES = AidStationRow::AID_EFFORT_CATEGORIES
  IN_BITKEY = SubSplit::IN_BITKEY
  OUT_BITKEY = SubSplit::OUT_BITKEY

  def post_initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:event, :aid_station],
                           exclusive: [:event, :aid_station],
                           class: self.class)
    @event = args[:event]
    @aid_station = args[:aid_station]
    @aid_station_row ||= AidStationRow.new(aid_station: aid_station, event_data: self, split_times: split_times_here)
    @times_container ||= args[:times_container] || SegmentTimesContainer.new(calc_model: :stats)
  end

  def recorded_in_day_and_time(effort)
    recorded_day_and_time(effort, sub_split_in)
  end

  def recorded_out_day_and_time(effort)
    recorded_day_and_time(effort, sub_split_out)
  end

  def event_id
    event.id
  end

  def expected_effort_rows
    @expected_effort_rows ||=
        category_efforts[:expected]
            .map { |effort| EffortProgressAidDetailRow.new(effort: effort, event_framework: self) }
            .sort_by { |effort| effort.expected_here_day_and_time }
  end

  def dropped_effort_rows
    category_efforts[:dropped_here]
        .map { |effort| EffortProgressAidDetailRow.new(effort: effort, event_framework: self) }
        .sort_by { |effort| effort.dropped_here_day_and_time }
  end

  private

  attr_reader :event, :aid_station_row

  def category_efforts
    @category_efforts ||=
        AID_EFFORT_CATEGORIES
            .map { |category| [category, efforts_from_ids(aid_station_row.category_effort_ids[category])] }.to_h
  end

  def split_times_by_effort
    @split_times_by_effort ||= event_split_times.group_by(&:effort_id)
  end

  def split_times_by_split
    @split_times_by_lap_split ||= event_split_times.group_by(&:split_id)
  end

  def event_split_times
    @event_split_times ||= event.split_times.ordered.struct_pluck(:effort_id, :lap, :split_id, :sub_split_bitkey)
  end

  def split_times_here
    @split_times_here ||= split_times_by_split[split_id]
  end

  def indexed_efforts
    @indexed_efforts ||= event_efforts.index_by(&:id)
  end

  def efforts_from_ids(effort_ids)
    effort_ids.map { |effort_id| indexed_efforts[effort_id] }
  end
end