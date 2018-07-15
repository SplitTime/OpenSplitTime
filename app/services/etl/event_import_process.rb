# frozen_string_literal: true

module ETL
  class EventImportProcess
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
        updated_live_times = LiveTime.where(id: live_times).includes(:event, :split)
        raw_times = updated_live_times.map do |lt|
          raw_time = RawTimeFromLiveTime.build(lt)
          raw_time.save!
          raw_time
        end

        event_group = event.event_group

        match_response = Interactors::MatchRawTimesToSplitTimes.perform!(event_group: event_group, raw_times: raw_times)
        if event_group.auto_live_times?
          unmatched_raw_times = match_response.resources[:unmatched]
          raw_time_rows = RowifyRawTimes.build(event_group: event_group, raw_times: unmatched_raw_times)
          Interactors::SubmitRawTimeRows.perform!(event_group: event_group, raw_time_rows: raw_time_rows,
                                                  force_submit: false, mark_as_pulled: false)
        end
        report_raw_times_available(event_group)
      end
    end

    def grouped_records
      @grouped_records ||= importer.saved_records.group_by(&:class)
    end
  end
end
