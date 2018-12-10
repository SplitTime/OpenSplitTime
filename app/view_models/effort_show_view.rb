# frozen_string_literal: true

class EffortShowView < EffortWithLapSplitRows

  delegate :full_name, :bib_number, :gender, :split_times, :finish_status, :report_url, :beacon_url, :photo,
           :overall_rank, :gender_rank, :started?, :finished?, :dropped?, :in_progress?, to: :effort
  delegate :event_name, :person, :start_time, :has_start_time?, :stopped?, to: :loaded_effort
  delegate :simple?, :multiple_sub_splits?, :multiple_laps?, :laps_unlimited?, :event_group, to: :event

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
    stopped? && (!finished? || laps_unlimited?)
  end

  private

  def problem_efforts
    event.efforts.reject(&:valid_status?).sort_by(&:last_name)
  end
end
