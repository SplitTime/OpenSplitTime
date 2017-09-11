class EffortShowView < EffortWithLapSplitRows

  delegate :full_name, :bib_number, :gender, :split_times, :finish_status, :report_url, :beacon_url, :photo_url,
           :overall_rank, :gender_rank, :started?, :finished?, :dropped?, :in_progress?, to: :effort
  delegate :event_name, :person, :start_time, to: :loaded_effort
  delegate :simple?, to: :event

end