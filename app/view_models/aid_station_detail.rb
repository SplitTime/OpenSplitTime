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
                           exclusive: [:event, :aid_station, :times_container],
                           class: self.class)
    @event = args[:event]
    @aid_station = args[:aid_station]
    @aid_station_row ||= AidStationRow.new(aid_station: aid_station, event_framework: self, split_times: split_times_here)
  end

  def expected_effort_data
    @expected_effort_data ||=
        category_effort_rows[:expected]
            .sort_by { |row| row.expected_here_info[:day_and_time] }
            .map { |row| row.extract_attributes(:effort_id, :bib_number, :full_name, :bio_historic,
                                                :last_reported_info, :due_next_info, :expected_here_info) }
  end

  def dropped_effort_data
    @dropped_effort_data ||=
        category_effort_rows[:dropped_here]
            .sort_by { |row| row.dropped_days_and_times.first }
            .map { |row| row.extract_attributes(:effort_id, :bib_number, :full_name, :bio_historic, :state_and_country,
                                                :prior_to_here_info, :dropped_days_and_times) }
  end

  def missed_effort_data
    @missed_effort_data ||=
        category_effort_rows[:missed]
            .sort_by { |row| row.bib_number }
            .map { |row| row.extract_attributes(:effort_id, :bib_number, :full_name, :bio_historic, :state_and_country,
                                                :prior_to_here_info, :after_here_info) }
  end

  def in_aid_effort_data
    @in_aid_effort_data ||=
        category_effort_rows[:in_aid]
            .sort_by { |row| row.recorded_in_here_info[:day_and_time] }
            .map { |row| row.extract_attributes(:effort_id, :bib_number, :full_name, :bio_historic, :state_and_country,
                                                :prior_to_here_info, :recorded_in_here_info) }
  end

  def recorded_in_effort_data
    @recorded_in_effort_data ||=
        category_effort_rows[:recorded_in]
            .sort_by { |row| row.recorded_in_here_info[:day_and_time] }
            .map { |row| row.extract_attributes(:effort_id, :bib_number, :full_name, :bio_historic, :state_and_country,
                                                :prior_to_here_info, :recorded_here_days_and_times, :after_here_info) }
  end

  private

  attr_reader :event, :aid_station_row

  def category_effort_rows
    @category_effort_rows ||=
        AID_EFFORT_CATEGORIES
            .map { |category| [category, rows_from_lap_keys(aid_station_row.category_effort_lap_keys[category])] }.to_h
  end

  def split_times_by_effort_lap
    @split_times_by_effort_lap ||= event_split_times.group_by(&:effort_lap_key)
  end

  def split_times_by_split
    @split_times_by_lap_split ||= event_split_times.group_by(&:split_id)
  end

  def event_split_times
    @event_split_times ||= event.split_times.ordered
                               .select(:effort_id, :lap, :split_id, :sub_split_bitkey, :time_from_start)
  end

  def split_times_here
    @split_times_here ||= split_times_by_split[split_id]
  end

  def indexed_efforts
    @indexed_efforts ||= event_efforts.index_by(&:id)
  end

  def rows_from_lap_keys(effort_lap_keys)
    effort_lap_keys.map do |effort_lap_key|
      EffortProgressAidDetail.new(effort: indexed_efforts[effort_lap_key.effort_id],
                                  event_framework: self,
                                  lap: effort_lap_key.lap,
                                  split_times: split_times_by_effort_lap[effort_lap_key],
                                  times_container: times_container)
    end
  end
end