# frozen_string_literal: true

class AidStationRow
  include ActionView::Helpers::TextHelper
  attr_reader :aid_station
  delegate :course, :organization, to: :event
  delegate :event, :split, :split_id, to: :aid_station
  delegate :expected_day_and_time, :prior_valid_display_data, :next_valid_display_data, to: :live_event

  AID_EFFORT_CATEGORIES = [:recorded_in, :recorded_out, :recorded_here, :stopped_here,
                           :dropped_here, :in_aid, :missed, :expected]
  IN_BITKEY = SubSplit::IN_BITKEY
  OUT_BITKEY = SubSplit::OUT_BITKEY

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: :aid_station,
                           exclusive: [:aid_station, :event_framework, :split_times],
                           class: self.class)
    @aid_station = args[:aid_station]
    @event_framework = args[:event_framework]
    @split_times = args[:split_times] || []
  end

  def category_effort_lap_keys
    @category_effort_lap_keys ||=
        AID_EFFORT_CATEGORIES.map { |category| [category, method("row_#{category}_lap_keys").call] }.to_h
  end

  def category_sizes
    @category_sizes ||= category_effort_lap_keys.transform_values(&:size)
  end

  def category_table_titles
    @category_table_titles ||=
        category_sizes.map { |category, count| [category, table_title(category, count)] }.to_h
  end

  def split_name
    split.base_name
  end

  private

  attr_reader :event_framework, :split_times
  delegate :lap_split_keys, :time_points, :efforts_stopped, :efforts_dropped, :efforts_started,
           :efforts_in_progress, to: :event_framework

  def row_recorded_in_lap_keys
    @row_recorded_in_lap_keys ||=
        split_times.select { |st| st.sub_split_bitkey == IN_BITKEY }.map(&:effort_lap_key)
  end

  def row_recorded_out_lap_keys
    @row_recorded_out_lap_keys ||=
        split_times.select { |st| st.sub_split_bitkey == OUT_BITKEY }.map(&:effort_lap_key)
  end

  def row_recorded_here_lap_keys
    row_recorded_in_lap_keys | row_recorded_out_lap_keys
  end

  def row_stopped_here_lap_keys
    @row_stopped_here_lap_keys ||=
        efforts_stopped.select { |effort| effort.stopped_split_id == split_id }
            .map { |effort| EffortLapKey.new(effort.id, effort.stopped_lap) }
  end

  def row_dropped_here_lap_keys
    @row_dropped_here_lap_keys ||=
        efforts_dropped.select { |effort| effort.stopped_split_id == split_id }
            .map { |effort| EffortLapKey.new(effort.id, effort.stopped_lap) }
  end

  def row_missed_lap_keys
    @row_recorded_later_lap_keys ||= efforts_started.flat_map { |effort| effort_lap_keys_missed(effort) }
  end

  def row_in_aid_lap_keys
    split_records_in_time_only? ? [] :
        row_recorded_in_lap_keys - row_recorded_out_lap_keys - row_dropped_here_lap_keys - row_missed_lap_keys
  end

  def row_expected_lap_keys
    efforts_in_progress.flat_map { |effort| effort_lap_key_expected(effort) }
  end

  def effort_lap_key_expected(effort) # Returns a single [effort_lap_key] or []
    lap_split_keys.elements_after(latest_lap_split_key(effort))
        .select { |lap_split_key| (lap_split_key.lap == latest_lap_split_key(effort).lap) && (lap_split_key.split_id == split_id) }
        .map { |lap_split_key| EffortLapKey.new(effort.id, lap_split_key.lap) }
  end

  def effort_lap_keys_missed(effort)
    time_points_recorded = Set.new(time_points_recorded(effort))
    time_points_required(effort)
        .reject { |time_point| time_points_recorded.include?(time_point) }
        .map { |time_point| EffortLapKey.new(effort.id, time_point.lap) }
        .uniq
  end

  def time_points_recorded(effort)
    (grouped_split_times[effort.id] || []).map(&:time_point)
  end

  def time_points_required(effort)
    time_points.elements_before(latest_time_point(effort))
        .select { |time_point| time_point.split_id == split_id }
  end

  def latest_lap_split_key(effort)
    LapSplitKey.new(effort.final_lap, effort.final_split_id)
  end

  def latest_time_point(effort)
    TimePoint.new(effort.final_lap, effort.final_split_id, effort.final_bitkey)
  end

  def grouped_split_times
    @grouped_split_times ||= split_times.group_by(&:effort_id)
  end

  def split_records_in_time_only?
    split.sub_split_bitmap == IN_BITKEY
  end

  def table_title(category, count)
    "#{pluralize(count, 'person')} #{category_phrase(category, count)} at #{split_name}"
  end

  def category_phrase(category, count)
    case category
    when :in_aid
      "#{'is'.pluralize(count)} in aid"
    when :missed
      'passed through without being recorded'
    when :stopped_here
      'stopped'
    when :dropped_here
      'dropped'
    when :expected
      "#{'is'.pluralize(count)} still expected"
    else
      "#{'was'.pluralize(count)} #{category.to_s.humanize(capitalize: false)}"
    end
  end
end
