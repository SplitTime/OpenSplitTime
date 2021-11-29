# frozen_string_literal: true

class EffortShowView < EffortWithLapSplitRows

  delegate :event_name, :person, :start_time, :has_start_time?, :stopped?, to: :loaded_effort
  delegate :simple?, :multiple_sub_splits?, :multiple_laps?, :laps_unlimited?, :event_group, to: :event

  def next_problem_effort
    proposed_effort = problem_efforts.element_after(effort) || problem_efforts.first
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

  def raw_times_count
    event_group.raw_times.where(bib_number: bib_number).size
  end

  private

  def problem_efforts
    event.efforts.reject(&:valid_status?).sort_by(&:last_name)
  end

  def times_exist_after_stop?
    stopped_split_id &&
        ((final_lap != stopped_lap) ||
            (final_split_id != stopped_split_id) ||
            (final_bitkey != stopped_bitkey))
  end
end