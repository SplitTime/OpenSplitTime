# frozen_string_literal: true

class EffortShowView < EffortWithLapSplitRows

  delegate :full_name, :bib_number, :gender, :split_times, :finish_status, :report_url, :beacon_url, :photo,
           :overall_rank, :gender_rank, :started?, :finished?, :dropped?, :in_progress?,
           :final_lap, :stopped_lap, :final_split_id, :stopped_split_id, :final_bitkey, :stopped_bitkey, to: :effort
  delegate :event_name, :person, :start_time, :has_start_time?, :stopped?, to: :loaded_effort
  delegate :simple?, :multiple_sub_splits?, :multiple_laps?, :laps_unlimited?, :event_group, to: :event

  def initialize(args)
    ArgsValidator.validate(params: args, required: :effort, exclusive: [:effort, :params], class: self.class)
    @effort = args[:effort].enriched
    @params = args[:params] || {}
  end

  def next_problem_effort
    proposed_effort = problem_efforts.elements_after(effort).first || problem_efforts.first
    proposed_effort unless proposed_effort == effort
  end

  def missing_start_time?
    ordered_split_times.none?(&:start?)
  end

  def needs_final_stop?
    ordered_split_times.present? && !finished? && !ordered_split_times.last.stopped_here?
  end

  def has_removable_stop?
    stopped? && (!finished? || laps_unlimited? || times_exist_after_stop?)
  end

  def showing_projected_times?
    show_projected_times?
  end

  private

  attr_reader :params

  def typical_effort
    @typical_effort ||= last_valid_split_time && effort_start_time &&
        TypicalEffort.new(event: event,
                          start_time: effort_start_time,
                          time_points: projectable_time_points,
                          expected_time_from_start: last_valid_split_time.time_from_start,
                          expected_time_point: last_valid_split_time.time_point)
  end

  def related_split_times(lap_split)
    lap_split.time_points.map do |time_point|
      completed_time_points.include?(time_point) ?
          indexed_split_times.fetch(time_point, SplitTime.new) :
          indexed_projected_split_times.fetch(time_point, SplitTime.new(projected: true))
    end
  end

  def indexed_projected_split_times
    @indexed_projected_split_times ||= typical_effort.ordered_split_times.index_by(&:time_point)
  end

  def last_valid_split_time
    ordered_split_times.select(&:valid_status).last
  end

  def projectable_time_points
    time_points - completed_time_points
  end

  def completed_time_points
    time_points.elements_before(last_split_time.time_point, inclusive: true)
  end

  def lap_split_rows_with_projected
    rows_from_lap_splits(lap_splits).first(2)
  end

  def problem_efforts
    event.efforts.reject(&:valid_status?).sort_by(&:last_name)
  end

  def times_exist_after_stop?
    stopped_split_id &&
        ((final_lap != stopped_lap) ||
            (final_split_id != stopped_split_id) ||
            (final_bitkey != stopped_bitkey))
  end

  def show_projected_times?
    params[:projected]&.to_boolean || false
  end
end
