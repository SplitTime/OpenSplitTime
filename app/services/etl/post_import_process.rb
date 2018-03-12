# frozen_string_literal: true

module ETL
  class PostImportProcess
    include BackgroundNotifiable

    def self.perform!(event, importer)
      new(event, importer).perform!
    end

    def initialize(event, importer)
      @event = event
      @importer = importer
    end

    def perform!
      process_splits
      process_efforts
      process_split_times
      process_live_times
    end

    private

    attr_reader :event, :importer

    def process_splits
      splits = grouped_records[Split]
      if splits.present?
        existing_splits = event.splits.to_set
        splits.each { |split| event.splits << split unless existing_splits.include?(split) }
      end
    end

    def process_efforts
      efforts = grouped_records[Effort]
      if efforts.present?
        EffortsAutoReconcileJob.perform_later(event, current_user: User.current)
      end
    end

    def process_split_times
      split_times = grouped_records[SplitTime]
      if split_times.present?
        updated_efforts = event.efforts.where(id: split_times.map(&:effort_id).uniq).includes(split_times: :split)
        Interactors::UpdateEffortsStatus.perform!(updated_efforts)

        if event.permit_notifications?
          notifier = BulkFollowerNotifier.new(split_times, multi_lap: event.multiple_laps?)
          notifier.notify
        end
      end
    end

    def process_live_times
      live_times = grouped_records[LiveTime]
      if live_times.present?
        match_response = Interactors::MatchLiveTimes.perform!(event: event, live_times: live_times)
        unmatched_live_times = match_response.resources[:unmatched_live_times]
        Interactors::CreateSplitTimesFromLiveTimes.perform!(event: event, live_times: unmatched_live_times) if event.auto_live_times?
        report_live_times_available(event.event_group)
      end
    end

    def grouped_records
      @grouped_records ||= importer.saved_records.group_by(&:class)
    end
  end
end
