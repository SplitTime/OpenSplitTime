# frozen_string_literal: true

class ProcessImportedRawTimesJob < ApplicationJob
  include BackgroundNotifiable

  queue_as :default

  def perform(event_group, raw_times)
    loaded_raw_times = ::RawTimes::SetAbsoluteTimeAndLap.perform(event_group, raw_times)
    match_response = Interactors::MatchRawTimesToSplitTimes.perform!(event_group: event_group, raw_times: loaded_raw_times)

    if match_response.successful?
      unmatched_raw_times = match_response.resources[:unmatched]
      raw_time_rows = RowifyRawTimes.build(event_group: event_group, raw_times: unmatched_raw_times)
      Interactors::SubmitRawTimeRows.perform!(event_group: event_group, raw_time_rows: raw_time_rows,
                                              force_submit: false, mark_as_pulled: false)
      report_raw_times_available(event_group)
    else
      Rails.logger.error(match_response.message_with_error_report)
    end
  end
end
