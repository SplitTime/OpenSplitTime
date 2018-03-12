# frozen_string_literal: true

class AidStationDetail < LiveEventFramework

  attr_reader :aid_station, :times_container
  delegate :course, :organization, :to_param, to: :event
  delegate :event, :split, :split_id, :open_time, :close_time, :status, :captain_name, :comms_crew_names,
           :comms_frequencies, :current_issues, to: :aid_station
  delegate :split_name, :category_sizes, :category_table_titles, to: :aid_station_row

  DEFAULT_DISPLAY_STYLE = :expected
  AID_EFFORT_CATEGORIES = AidStationRow::AID_EFFORT_CATEGORIES
  IN_BITKEY = SubSplit::IN_BITKEY
  OUT_BITKEY = SubSplit::OUT_BITKEY
  UNIVERSAL_ATTRIBUTES = [:effort_slug, :bib_number, :full_name, :bio_historic]
  VIEW_ATTRIBUTES = {expected: {default_sort_field: :expected_here_info, default_sort_order: :asc, custom_attributes: [:last_reported_info, :due_next_info, :expected_here_info]},
                     stopped_here: {default_sort_field: :stopped_here_info, default_sort_order: :asc, custom_attributes: [:state_and_country, :prior_to_here_info, :stopped_here_info]},
                     dropped_here: {default_sort_field: :dropped_here_info, default_sort_order: :asc, custom_attributes: [:state_and_country, :prior_to_here_info, :dropped_here_info]},
                     missed: {default_sort_field: :after_here_info, default_sort_order: :asc, custom_attributes: [:state_and_country, :prior_to_here_info, :recorded_here_info, :after_here_info]},
                     in_aid: {default_sort_field: :recorded_here_info, default_sort_order: :asc, custom_attributes: [:state_and_country, :prior_to_here_info, :recorded_here_info]},
                     recorded_here: {default_sort_field: :recorded_here_info, default_sort_order: :desc, custom_attributes: [:state_and_country, :prior_to_here_info, :recorded_here_info, :after_here_info]}}
                        .with_indifferent_access

  def post_initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:event, :aid_station],
                           exclusive: [:event, :aid_station, :times_container, :params],
                           class: self.class)
    @event = args[:event]
    @aid_station = args[:aid_station]
    @params = args[:params]
    @aid_station_row ||= AidStationRow.new(aid_station: aid_station, event_framework: self, split_times: split_times_here)
  end

  def effort_data
    return @effort_data if defined?(@effort_data)
    rows = category_effort_rows[display_style].sort_by { |row| row.send(sort_field(display_style)) }
               .map { |row| row.extract_attributes(*extractable_attributes(display_style)) }
    @effort_data = (sort_order(display_style) == :desc ? rows.reverse : rows)
  end

  def display_style
    params[:display_style]&.to_sym || DEFAULT_DISPLAY_STYLE
  end

  def existing_sort
    params.original_params[:sort]
  end

  def prior_aid_station
    ordered_aid_stations.elements_before(aid_station)&.last
  end

  def next_aid_station
    ordered_aid_stations.elements_after(aid_station)&.first
  end

  def event_group_aid_stations
    EventGroupSplitAnalyzer.new(event_group).aid_stations_by_event(split_name)
  end

  private

  attr_reader :params, :aid_station_row
  delegate :event_group, :ordered_aid_stations, to: :event

  def category_effort_rows
    @category_effort_rows ||=
        AID_EFFORT_CATEGORIES
            .map { |category| [category, rows_from_lap_keys(aid_station_row.category_effort_lap_keys[category])] }
            .to_h.with_indifferent_access
  end

  def extractable_attributes(display_style)
    (UNIVERSAL_ATTRIBUTES + VIEW_ATTRIBUTES[display_style][:custom_attributes])
  end

  def sort_field(display_style)
    sort_param_field || VIEW_ATTRIBUTES[display_style][:default_sort_field]
  end

  def sort_order(display_style)
    sort_param_order || VIEW_ATTRIBUTES[display_style][:default_sort_order]
  end

  def split_times_by_effort
    @split_times_by_effort ||= event_split_times.group_by(&:effort_id)
  end

  def split_times_by_split
    @split_times_by_split ||= event_split_times.group_by(&:split_id)
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
    effort_lap_keys.map do |key|
      EffortProgressAidDetail.new(effort: indexed_efforts[key.effort_id],
                                  event_framework: self,
                                  lap: key.lap,
                                  effort_split_times: split_times_by_effort[key.effort_id],
                                  times_container: times_container)
    end
  end

  def sort_param_field
    sort_param.first
  end

  def sort_param_order
    sort_param.last
  end

  def sort_param
    (params[:sort].first || []).map(&:to_sym)
  end
end
