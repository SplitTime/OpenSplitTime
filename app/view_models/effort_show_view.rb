class EffortShowView < EffortWithLapSplitRows

  delegate :full_name, :bib_number, :gender, :split_times, :finish_status, :report_url, :beacon_url, :photo,
           :overall_rank, :gender_rank, :started?, :finished?, :dropped?, :in_progress?, to: :effort
  delegate :event_name, :person, :start_time, to: :loaded_effort
  delegate :simple?, to: :event

  def next_problem_effort
    proposed_effort = problem_efforts.elements_after(effort).first || problem_efforts.first
    proposed_effort unless proposed_effort == effort
  end

  private

  def problem_efforts
    event.efforts.reject(&:valid_status?).sort_by(&:last_name)
  end
end
