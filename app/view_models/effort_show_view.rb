class EffortShowView < EffortWithLapSplitRows

  delegate :full_name, :event_name, :participant, :bib_number, :gender, :split_times,
           :finish_status, :report_url, :beacon_url, :start_time, :photo_url,
           :overall_place, :gender_place, :started?, :finished?, :dropped?, :in_progress?, to: :effort
  delegate :simple?, to: :event

end