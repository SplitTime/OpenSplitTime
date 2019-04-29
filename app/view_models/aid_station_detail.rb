# frozen_string_literal: true

class AidStationDetail < LiveEventFramework
  include SplitAnalyzable

  attr_reader :event, :times_container
  delegate :course, :organization, :laps_unlimited?, :to_param, to: :event
  delegate :category_sizes, :category_table_titles, to: :aid_station_row

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
                           required: [:event],
                           exclusive: [:event, :parameterized_split_name, :params, :times_container],
                           class: self.class)
    @event = args[:event]
    @parameterized_split_name = args[:parameterized_split_name].in?(parameterized_split_names) ? args[:parameterized_split_name] : parameterized_split_names.last
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

  def split
    event.splits.find { |split| split.parameterized_base_name == parameterized_split_name } || event.ordered_splits.last
  end

  private

  attr_reader :parameterized_split_name, :params, :aid_station_row
  delegate :event_group, to: :event

  def aid_station
    event.aid_stations.find { |as| as.split == split }
  end

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
                               .select('effort_id, lap, split_id, sub_split_bitkey, absolute_time, split_times.data_status, event_groups.home_time_zone')
                               .joins(effort: {event: :event_group})
  end

  def split_times_here
    return {} unless split.present?
    @split_times_here ||= split_times_by_split[split.id]
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

  def split_analyzable
    event
  end
end
