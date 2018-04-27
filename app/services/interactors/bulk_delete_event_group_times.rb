# frozen_string_literal: true

module Interactors
  class BulkDeleteEventGroupTimes
    include ActionView::Helpers::TextHelper
    include Interactors::Errors

    def self.perform!(event_group)
      new(event_group).perform!
    end

    def initialize(event_group)
      @event_group = event_group
      @errors = []
    end

    def perform!
      ActiveRecord::Base.transaction do
        delete_live_times
        delete_raw_times
        delete_split_times
        raise ActiveRecord::Rollback if errors.present?
      end
      Interactors::Response.new(errors, message, {})
    end

    private

    attr_reader :event_group, :errors

    def delete_live_times
      @live_time_count = LiveTime.where(event_id: event_group.events).delete_all
    rescue ActiveRecord::ActiveRecordError => exception
      errors << active_record_error(exception)
    end

    def delete_raw_times
      @raw_time_count = RawTime.where(event_group_id: event_group).delete_all
    rescue ActiveRecord::ActiveRecordError => exception
      errors << active_record_error(exception)
    end

    def delete_split_times
      efforts = Effort.where(event_id: event_group.events)
      @split_time_count = SplitTime.where(effort_id: efforts).delete_all
    rescue ActiveRecord::ActiveRecordError => exception
      errors << active_record_error(exception)
    end

    def message
      if errors.present?
        "Unable to delete times"
      else
        "Deleted #{pluralize(@live_time_count, 'live time')}, #{pluralize(@raw_time_count, 'raw time')}, and #{pluralize(@live_time_count, 'split time')}"
      end
    end
  end
end
