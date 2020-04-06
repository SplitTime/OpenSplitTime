# frozen_string_literal: true

class ProcessImportedRawTimesJob < ApplicationJob
  include BackgroundNotifiable

  queue_as :default

  def perform(event_group, raw_times)
    loaded_raw_times = ::RawTimes::SetAbsoluteTimeAndLap.perform(event_group, raw_times)
    match_response = ::Interactors::MatchRawTimesToSplitTimes.perform!(event_group: event_group, raw_times: loaded_raw_times)

    if match_response.successful?
      unmatched_raw_times = match_response.resources[:unmatched]
      update_response = ::Interactors::UpdateEffortsFromRawTimes.perform!(event_group, unmatched_raw_times)
      Rails.logger.error(update_response.message_with_error_report) unless update_response.successful?

      upserted_split_times = update_response.resources[:upserted_split_times]
      BulkProgressNotifier.notify(upserted_split_times) if event_group.permit_notifications?

      report_raw_times_available(event_group)
    else
      Rails.logger.error(match_response.message_with_error_report)
    end
  end
end
